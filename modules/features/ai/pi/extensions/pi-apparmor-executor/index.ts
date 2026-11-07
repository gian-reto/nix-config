import { constants, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createLsToolDefinition,
  createPowerShellToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  getAgentDir,
  getPackageDir,
  type ExtensionAPI,
  type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { createSandbox } from "./executor.ts";
import { createConfinedGrep } from "./grep.ts";
import { withConfinedPreview } from "./preview.ts";

export default function apparmorExecutor(pi: ExtensionAPI): void {
  const cwd = process.cwd();
  const sandbox = createSandbox(() => {
    const configurationPath = join(
      getAgentDir(),
      "pi-apparmor-executor",
      "config.json",
    );
    let configuration: unknown;
    try {
      configuration = JSON.parse(readFileSync(configurationPath, "utf8"));
    } catch (error) {
      throw new Error(
        `Cannot load ${configurationPath}: ${error instanceof Error ? error.message : String(error)}`,
        { cause: error },
      );
    }
    if (
      typeof configuration !== "object" ||
      configuration === null ||
      !("profile" in configuration) ||
      typeof configuration.profile !== "string" ||
      !configuration.profile.trim() ||
      configuration.profile.includes("\0")
    ) {
      throw new Error(
        `Set "profile" in ${configurationPath} to the name of an enforced AppArmor profile`,
      );
    }
    const excludedEnvironmentVariables =
      "excludedEnvironmentVariables" in configuration
        ? configuration.excludedEnvironmentVariables
        : [];
    if (
      !Array.isArray(excludedEnvironmentVariables) ||
      !excludedEnvironmentVariables.every(
        (name: unknown): name is string =>
          typeof name === "string" && /^[A-Za-z_][A-Za-z0-9_]*$/.test(name),
      )
    ) {
      throw new Error(
        `Set "excludedEnvironmentVariables" in ${configurationPath} to an array of environment-variable names`,
      );
    }
    return {
      profileName: configuration.profile,
      excludedEnvironmentVariables,
      sdk: pathToFileURL(join(getPackageDir(), "dist", "index.js")).href,
      worker: fileURLToPath(new URL("./worker.ts", import.meta.url)),
    };
  });
  const readOperations = {
    readFile: sandbox.readFile,
    access: (path: string) => sandbox.access(path, constants.R_OK),
  };

  function register<
    TParams extends ToolDefinition["parameters"],
    TDetails,
    TState,
  >(
    factory: (
      settings?: ReturnType<ExtensionAPI["getSettings"]>,
    ) => ToolDefinition<TParams, TDetails, TState>,
  ): void {
    pi.registerTool({
      ...factory(),
      defaultActive: false,
      execute: (id, args, signal, update, ctx) =>
        sandbox.withSignal(signal, () =>
          factory(pi.getSettings()).execute(id, args, signal, update, ctx),
        ),
    });
  }

  register((settings) =>
    createBashToolDefinition(cwd, {
      operations: sandbox.shell("bash", settings?.shellPath),
      commandPrefix: settings?.shellCommandPrefix,
      shellPath: settings?.shellPath,
    }),
  );
  register(() =>
    withConfinedPreview(
      createEditToolDefinition(cwd, {
        operations: {
          ...readOperations,
          writeFile: sandbox.writeFile,
          access: (path) =>
            sandbox.access(path, constants.R_OK | constants.W_OK),
        },
      }),
      sandbox,
    ),
  );
  register(() =>
    createFindToolDefinition(cwd, {
      operations: {
        exists: sandbox.exists,
        glob: (pattern, cwd, options) =>
          sandbox.call<string[]>({
            operation: "glob",
            pattern,
            cwd,
            ...options,
          }),
      },
    }),
  );
  register(() => createConfinedGrep(cwd, sandbox));
  register(() =>
    createLsToolDefinition(cwd, {
      operations: {
        exists: sandbox.exists,
        stat: sandbox.stat,
        readdir: (path) =>
          sandbox.call<string[]>({ operation: "readdir", path }),
      },
    }),
  );
  register(() =>
    createPowerShellToolDefinition(cwd, {
      operations: sandbox.shell("powershell"),
    }),
  );
  register((settings) =>
    createReadToolDefinition(cwd, {
      autoResizeImages: settings?.images?.autoResize ?? true,
      operations: {
        ...readOperations,
        detectImageMimeType: (path) =>
          sandbox.call<string | null>({ operation: "mime", path }),
      },
    }),
  );
  register(() =>
    createWriteToolDefinition(cwd, {
      operations: {
        writeFile: sandbox.writeFile,
        mkdir: (path) => sandbox.call<void>({ operation: "mkdir", path }),
      },
    }),
  );

  pi.on("user_bash", () => ({
    operations: sandbox.shell("bash", pi.getSettings().shellPath),
  }));
}
