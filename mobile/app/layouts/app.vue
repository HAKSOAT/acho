<script setup lang="ts">
import AppHeader from "~/composables/app/AppHeader.vue";
import AppBottomNav from "~/composables/nav/AppBottomNav.vue";
</script>

<template>
  <app-header class="px-6 pt-12" />
  <main class="mt-20 px-6">
    <slot />
  </main>
  <app-bottom-nav />
</template>
