# ╔══════════════════════════════════════════════════════════════════╗
# ║  Neovim — Éditeur terminal avec LSP, Treesitter, Telescope     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration minimale mais fonctionnelle de Neovim :
# - LSP : nil (Nix), pyright (Python), rust-analyzer (Rust)
# - Treesitter : coloration syntaxique intelligente
# - Telescope : recherche fuzzy de fichiers et texte
# - Catppuccin : thème (cohérent avec le reste du système)
#
# Cette config est suffisante pour de l'édition rapide en terminal.
# Pour du dev intensif, VSCode reste l'éditeur principal.

{ config, pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;    # $EDITOR = nvim
    viAlias = true;          # vi → nvim
    vimAlias = true;         # vim → nvim

    # ── Plugins Nix ────────────────────────────────────────────────
    plugins = with pkgs.vimPlugins; [
      # Thème
      catppuccin-nvim

      # LSP — serveurs de langage
      nvim-lspconfig

      # Autocomplétion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path

      # Snippets (requis par nvim-cmp)
      luasnip
      cmp_luasnip

      # Treesitter — coloration syntaxique intelligente
      (nvim-treesitter.withPlugins (p: [
        p.nix p.lua p.python p.rust p.javascript p.typescript
        p.json p.yaml p.toml p.bash p.markdown p.html p.css
        p.dockerfile p.go
      ]))

      # Telescope — recherche fuzzy
      telescope-nvim
      plenary-nvim       # Dépendance de Telescope

      # Navigation et UI
      nvim-tree-lua      # Explorateur de fichiers
      nvim-web-devicons  # Icônes
      lualine-nvim        # Barre de statut
      gitsigns-nvim       # Marqueurs Git dans la gouttière
      indent-blankline-nvim # Guides d'indentation
      which-key-nvim      # Affiche les keybinds disponibles

      # Édition
      nvim-autopairs      # Fermer automatiquement les parenthèses
      comment-nvim        # gcc pour commenter/décommenter
      nvim-surround       # Manipulation des paires (quotes, brackets)
    ];

    # ── Configuration Lua ──────────────────────────────────────────
    extraLuaConfig = ''
      -- ═══════════════════════════════════════════════════════════
      -- Options générales
      -- ═══════════════════════════════════════════════════════════
      vim.g.mapleader = " "              -- Leader = Espace
      vim.opt.number = true              -- Numéros de ligne
      vim.opt.relativenumber = true      -- Numéros relatifs
      vim.opt.tabstop = 2                -- Taille des tabs
      vim.opt.shiftwidth = 2             -- Indentation
      vim.opt.expandtab = true           -- Espaces au lieu de tabs
      vim.opt.smartindent = true
      vim.opt.termguicolors = true       -- Couleurs 24-bit
      vim.opt.signcolumn = "yes"         -- Toujours afficher la gouttière
      vim.opt.clipboard = "unnamedplus"  -- Presse-papier système
      vim.opt.undofile = true            -- Historique d'annulation persistant
      vim.opt.ignorecase = true          -- Recherche insensible à la casse
      vim.opt.smartcase = true           -- Sauf si majuscule utilisée
      vim.opt.scrolloff = 8              -- Marge de scroll
      vim.opt.cursorline = true          -- Surligner la ligne courante
      vim.opt.splitright = true          -- Split à droite par défaut
      vim.opt.splitbelow = true          -- Split en bas par défaut

      -- ═══════════════════════════════════════════════════════════
      -- Thème Catppuccin
      -- ═══════════════════════════════════════════════════════════
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          telescope = { enabled = true },
          indent_blankline = { enabled = true },
          which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")

      -- ═══════════════════════════════════════════════════════════
      -- LSP — Serveurs de langage
      -- ═══════════════════════════════════════════════════════════
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Nix
      lspconfig.nil_ls.setup({ capabilities = capabilities })

      -- Python
      lspconfig.pyright.setup({ capabilities = capabilities })

      -- Rust (rust-analyzer)
      lspconfig.rust_analyzer.setup({ capabilities = capabilities })

      -- Go
      lspconfig.gopls.setup({ capabilities = capabilities })

      -- TypeScript / JavaScript
      lspconfig.ts_ls.setup({ capabilities = capabilities })

      -- Keybinds LSP (actifs quand un serveur est attaché)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })

      -- ═══════════════════════════════════════════════════════════
      -- Autocomplétion (nvim-cmp)
      -- ═══════════════════════════════════════════════════════════
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- ═══════════════════════════════════════════════════════════
      -- Treesitter
      -- ═══════════════════════════════════════════════════════════
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })

      -- ═══════════════════════════════════════════════════════════
      -- Telescope — Recherche fuzzy
      -- ═══════════════════════════════════════════════════════════
      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Fichiers" })
      vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Grep" })
      vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "Aide" })

      -- ═══════════════════════════════════════════════════════════
      -- Plugins UI
      -- ═══════════════════════════════════════════════════════════
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Explorateur" })

      require("lualine").setup({ options = { theme = "catppuccin" } })
      require("gitsigns").setup()
      require("ibl").setup()
      require("which-key").setup()
      require("nvim-autopairs").setup()
      require("Comment").setup()
      require("nvim-surround").setup()
    '';
  };
}
