local M = {}

local make_opts = function(defaults)
  -- use this function notation to build some variables
  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", ".project" }
  local root_dir = require("jdtls.setup").find_root(root_markers)
  -- local next_up = root_dir
  -- while next_up ~= nil and next_up ~= "" and next_up ~= "/" do
  --   next_up = vim.fs.root(vim.fs.dirname(root_dir), root_markers)
  --   if next_up ~= nil and next_up ~= "" then
  --     root_dir = next_up
  --   end
  -- end

  -- calculate workspace dir
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local workspace_dir = vim.fn.stdpath "data" .. "/site/java/workspace-root/" .. project_name
  vim.fn.mkdir(workspace_dir, "p")
  -- TODO: unique workspace for every unique paths.
  -- Base names truncated at some length and then suffix them with hash value of their absolute path.

  -- validate operating system
  local uname = vim.uv.os_uname()
  local config_suffixes = {
    Linux_x86_64 = "_linux",
    Linux_arm64 = "_linux_arm",
    Darwin_x86_64 = "_mac",
    Darwin_arm64 = "_mac_arm",
    Windows_x86_64 = "_win",
  }
  local suf = config_suffixes[uname.sysname .. "_" .. uname.machine]
  if suf == nil then
    vim.notify("jdtls: Could not detect valid OS", vim.log.levels.ERROR)
  end
  -- TODO: handle syntax only servers
  -- if ss then
  --     suf = "_ss" .. suf
  -- end
  local config_name = "config" .. suf

  local jdtls_home = vim.fn.expand "$HOME/.local/eclipse.jdt.ls"
  local config_path = jdtls_home .. "/" .. config_name
  local launcher_path = vim.split(vim.fn.glob(jdtls_home .. "/plugins/org.eclipse.equinox.launcher_*.jar"), "\n")[1]
  return {
    cmd = {
      vim.fn.expand "$HOME/.local/jdk-21.0.2/bin/java",
      -- params are basically stolen from https://github.com/redhat-developer/vscode-java
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",
      -- See https://github.com/redhat-developer/vscode-java/issues/2264
      -- It requires the internal API sun.nio.fs.WindowsFileAttributes.isDirectoryLink() to check if a Windows directory is symlink.
      "--add-opens",
      "java.base/sun.nio.fs=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED",
      "--add-opens",
      "jdk.javadoc/jdk.javadoc.internal.doclets.formats.html.taglets.snippet=ALL-UNNAMED",
      "--add-opens",
      "jdk.javadoc/jdk.javadoc.internal.doclets.formats.html.taglets=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.platform=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.resources=ALL-UNNAMED",
      "--add-opens",
      "jdk.compiler/com.sun.tools.javac.jvm=ALL-UNNAMED",
      "--add-opens",
      "jdk.zipfs/jdk.nio.zipfs=ALL-UNNAMED",
      "--add-opens",
      "java.compiler/javax.tools=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.nio.channels=ALL-UNNAMED",
      "--add-opens",
      "java.base/sun.nio.ch=ALL-UNNAMED",
      "-DICompilationUnitResolver=org.eclipse.jdt.core.dom.JavacCompilationUnitResolver",
      "-DCompilationUnit.DOM_BASED_OPERATIONS=true",
      "-DAbstractImageBuilder.compilerFactory=org.eclipse.jdt.internal.javac.JavacCompilerFactory",
      -- '-DCompilationUnit.codeComplete.DOM_BASED_OPERATIONS=true',
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.level=ALL",
      "-Dfile.encoding=utf8",
      "-jar",
      launcher_path,
      "-configuration",
      config_path,
      "-javaagent:" .. vim.fn.expand "$HOME/.local/lombok/lombok.jar",
      "-data",
      workspace_dir,
    },
    root_dir = root_dir,
    settings = {
      java = {
        home = vim.fn.expand "$HOME/.local/jdk-21.0.2",
        runtimes = {
          { name = "JavaSE-11", path = vim.fn.expand "$HOME/.local/jdk-11.0.2" },
          { name = "JavaSE-12", path = vim.fn.expand "$HOME/.local/jdk-12.0.2" },
          { name = "JavaSE-17", path = vim.fn.expand "$HOME/.local/jdk-17.0.2" },
          { name = "JavaSE-21", path = vim.fn.expand "$HOME/.local/jdk-21.0.2" },
          { name = "JavaSE-22", path = vim.fn.expand "$HOME/.local/jdk-22.0.2" },
          { name = "JavaSE-23", path = vim.fn.expand "$HOME/.local/jdk-23.0.2" },
          { name = "JavaSE-24", path = vim.fn.expand "$HOME/.local/jdk-24" },
        },
        eclipse = { downloadSources = true },
        configuration = { updateBuildConfiguration = "interactive" },
        maven = { downloadSources = true },
        implementationsCodeLens = { enabled = true },
        referencesCodeLens = { enabled = true },
        inlayHints = { parameterNames = { enabled = "all" } },
        signatureHelp = { enabled = true },
        import = {
          gradle = {
            -- arguments = { "localDistro" },
            enabled = true,
            java = {
              --  home = vim.fn.expand "$HOME/.local/jdk-17.0.2",
              -- home =  vim.fn.expand "$JAVA_HOME",
            },
            jvmArguments = {
              -- "-Xlint:unchecked",
              -- "-Xmx4g",
              -- "-XX:MaxMetaspaceSize=2g",
              -- "-Dkotlin.daemon.jvm.options=-Xmx1500m",
            },
            wrapper = {
              enabled = true,
            },
          },
        },
        completion = {
          favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*",
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
      },
    },
    init_options = {
      bundles = {},
    },
    handlers = {
      ["$/progress"] = function() end, -- disable progress updates.
      extendedClientCapabilities = {
        clientHoverProvider = false,
      },
    },
    filetypes = { "java" },
    on_attach = function(...)
      --      require("jdtls").setup_dap { hotcodereplace = "auto" }
      defaults.on_attach(...)
    end,
  }
end

M.config = function(servers, defaults)
  vim.api.nvim_create_autocmd("Filetype", {
    pattern = "java", -- autocmd to start jdtls
    callback = function()
      local opts = make_opts(defaults)
      if opts.root_dir and opts.root_dir ~= "" then
        require("jdtls").start_or_attach(vim.tbl_deep_extend("keep", opts, defaults))
      else
        vim.notify("jdtls: root_dir not found. Please specify a root marker", vim.log.levels.ERROR)
      end
    end,
  })
  -- create autocmd to load main class configs on LspAttach.
  -- This ensures that the LSP is fully attached.
  -- See https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
  vim.api.nvim_create_autocmd("LspAttach", {
    pattern = "*.java",
    callback = function(args)
      --      local client = vim.lsp.get_client_by_id(args.data.client_id)
      -- ensure that only the jdtls client is activated
      --     if client and client.name == "jdtls" then
      --       require("jdtls.dap").setup_dap_main_class_configs()
      --   end
    end,
  })
end

return M
