const test = require("node:test");
const assert = require("node:assert/strict");
const request = require("supertest");

const app = require("../src/server");

test("GET / returns application status", async () => {
  const response = await request(app).get("/");

  assert.equal(response.status, 200);
  assert.equal(response.body.status, "running");
  assert.equal(response.body.message, "Cloud DevOps Lab API");
});

test("GET /health returns healthy status", async () => {
  const response = await request(app).get("/health");

  assert.equal(response.status, 200);
  assert.equal(response.body.status, "ok");
  assert.equal(response.body.service, "cloud-devops-lab-app");
});

test("GET /version returns application version", async () => {
  const response = await request(app).get("/version");

  assert.equal(response.status, 200);
  assert.equal(response.body.version, "1.0.0");
});
