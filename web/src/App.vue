<script setup lang="ts">
import {
  Alert as AAlert,
  Card as ACard,
  Layout as ALayout,
  Spin as ASpin,
  Typography as ATypography,
} from "ant-design-vue";
import { onMounted, ref } from "vue";

import { api } from "./api/client";

const ALayoutContent = ALayout.Content;
const ATypographyTitle = ATypography.Title;
const ATypographyParagraph = ATypography.Paragraph;

type HealthState = "checking" | "available" | "unavailable";

const healthState = ref<HealthState>("checking");

async function checkHealth() {
  healthState.value = "checking";
  try {
    const { data, response } = await api.GET("/healthz");
    healthState.value = response.ok && data?.status === "ok" ? "available" : "unavailable";
  } catch {
    healthState.value = "unavailable";
  }
}

onMounted(checkHealth);
</script>

<template>
  <ALayout class="page-shell">
    <ALayoutContent>
      <main class="status-page">
        <ACard class="status-card">
          <ATypographyTitle :level="1">
            CloudPilot-PVE
          </ATypographyTitle>
          <ATypographyParagraph type="secondary">
            Safe, auditable Proxmox self-service.
          </ATypographyParagraph>

          <div
            v-if="healthState === 'checking'"
            class="status-block"
            aria-live="polite"
          >
            <ASpin tip="Checking backend..." />
          </div>
          <AAlert
            v-else-if="healthState === 'available'"
            type="success"
            show-icon
            message="Backend available"
            description="The CloudPilot API is ready."
          />
          <AAlert
            v-else
            type="error"
            show-icon
            message="Backend connection failed"
            description="The service is currently unavailable. Try again later."
          />
        </ACard>
      </main>
    </ALayoutContent>
  </ALayout>
</template>
