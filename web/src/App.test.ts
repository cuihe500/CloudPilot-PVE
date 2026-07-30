import { flushPromises, mount } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";

import App from "./App.vue";

const { getHealth } = vi.hoisted(() => ({ getHealth: vi.fn() }));

vi.mock("./api/client", () => ({
  api: { GET: getHealth },
}));

beforeEach(() => {
  getHealth.mockReset();
});

describe("backend health", () => {
  it("shows the available state for a valid response", async () => {
    getHealth.mockResolvedValue({
      data: { status: "ok" },
      response: { ok: true },
    });

    const wrapper = mount(App);
    expect(wrapper.text()).toContain("Checking backend");
    await flushPromises();
    expect(wrapper.text()).toContain("Backend available");
  });

  it("shows a non-sensitive error when the request fails", async () => {
    getHealth.mockRejectedValue(new Error("secret upstream detail"));

    const wrapper = mount(App);
    await flushPromises();
    expect(wrapper.text()).toContain("Backend connection failed");
    expect(wrapper.text()).not.toContain("secret upstream detail");
  });
});
