<script lang="ts" setup>
import type { NavigationMenuItem } from "@nuxt/ui";
import BottomNavItem from "./AppBottomNavItem.vue";

const navigationItems: NavigationMenuItem[] = [
  {
    label: "home",
    to: "/dashboard",
    icon: "ri:home-line",
    trailingIcon: "ri:home-fill",
  },
  {
    label: "discover",
    icon: "heroicons:magnifying-glass",
    to: "/dashboard/discover",
    trailingIcon: "heroicons:magnifying-glass-20-solid",
  },

  {
    label: "library",
    icon: "heroicons:book-open",
    to: "/dashboard/library",
    trailingIcon: "heroicons:book-open-solid",
  },
  {
    label: "Settings",
    icon: "heroicons:cog-6-tooth",
    to: "/dashboard/settings",
    trailingIcon: "heroicons:cog-6-tooth-solid",
  },
];
</script>

<template>
  <footer
    class="fixed bottom-0 justify-center items-center w-full z-50 border-t border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-900"
  >
    <UNavigationMenu
      color="primary"
      orientation="horizontal"
      content-orientation="horizontal"
      :items="navigationItems"
      highlight-color="error"
      id="bottomNav"
      :ui="{
        list: 'flex justify-between px-6 w-screen items-center',
      }"
      collapsed
    >
      <template #item="{ item, active }">
        <NuxtLink :to="item.to" class="flex flex-col items-center">
          <BottomNavItem
            :icon="active ? item.trailingIcon : item.icon"
            :active="active"
            :label="String(item.label)"
          />
        </NuxtLink>
      </template>
    </UNavigationMenu>
  </footer>
</template>

<style>
#bottomNav a::before {
  background: transparent;
}
</style>
