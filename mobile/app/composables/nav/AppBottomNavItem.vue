<template>
  <button class="flex flex-col justify-between items-center">
    <UIcon
      :name="icon"
      class="size-6 transition-transform duration-200"
      :class="{ 'scale-110 ease-in-out': active }"
    />
    <span class="text-xs mt-1 capitalize"> {{ label }}</span>
  </button>
</template>

<script lang="ts" setup>
defineProps({
  icon: {
    type: String,
    required: true,
  },
  active: {
    type: Boolean,
    default: false,
  },
  label: {
    type: String,
    required: true,
  },
});
</script>
