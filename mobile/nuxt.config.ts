// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: true },
  app: {
    head: {
      charset: "utf-16",
      viewport: "width=device-width, initial-scale=1, maximum-scale=1",
      meta: [
        { name: "width", content: "device-width" },
        { name: "initial-scale", content: "1.0" },
        { name: "maximum-scale", content: "1.0" },
        { name: "user-scalable", content: "0" },
      ],
      htmlAttrs: {
        lang: "en",
      },
    },
  },

  router: {
    options: {
      scrollBehaviorType: "smooth",
    },
  },
  colorMode: {
    fallback: "light",
    classSuffix: "",
    globalName: "__NUXT_COLOR_MODE__",
    storageKey: "nuxt-color-mode",
  },
  experimental: {
    typedPages: true,
  },

  css: ["~/assets/css/main.css"],
  modules: [
    "@nuxt/fonts",
    "@nuxt/hints",
    "@nuxt/icon",
    "@nuxt/image",
    "@nuxt/eslint",
    "@nuxtjs/color-mode",
  ],
  vite: {
    clearScreen: false,
    envPrefix: ["VITE_", "TAURI_"],
    server: {
      strictPort: true,
      hmr: {
        protocol: "ws",
        host: "0.0.0.0",
        port: 3000,
      },
      watch: {
        ignored: ["**/src-tauri/**"],
      },
    },
  },
  eslint: {
    config: {
      standalone: false,
      stylistic: true,
    },
  },
});