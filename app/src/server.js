const express = require("express");

const app = express();

const port = process.env.PORT || 3003;
const appVersion = process.env.APP_VERSION || "1.0.0";

app.get("/", (_req, res) => {
  res.status(200).json({
    message: "Cloud DevOps Lab API",
    status: "running",
  });
});

app.get("/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "cloud-devops-lab-app",
  });
});

app.get("/version", (_req, res) => {
  res.status(200).json({
    version: appVersion,
  });
});

if (require.main === module) {
  app.listen(port, "0.0.0.0", () => {
    console.log(`Cloud DevOps Lab app listening on port ${port}`);
  });
}

module.exports = app;
