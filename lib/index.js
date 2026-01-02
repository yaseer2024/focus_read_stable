const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 🔥 CONFIG ENDPOINT
app.get("/config", (req, res) => {
  const baseUrl =
    req.protocol + "://" + req.get("host");

  res.json({
    apiBaseUrl: baseUrl
  });
});

// 📚 FREE BOOKS LIST
app.get("/free-books", (req, res) => {
  const dir = path.join(__dirname, "uploads/free_pdfs");

  if (!fs.existsSync(dir)) {
    return res.json([]);
  }

  const files = fs.readdirSync(dir).filter(f =>
    f.toLowerCase().endsWith(".pdf")
  );

  res.json(
    files.map(f => ({
      id: f,
      title: f.replace(".pdf", "")
    }))
  );
});

// 📄 PDF SERVING (PRIMARY)
app.use(
  "/free_pdfs",
  express.static(path.join(__dirname, "uploads/free_pdfs"))
);

// 📄 PDF SERVING (BACKWARD COMPATIBILITY)
app.use(
  "/uploads/free_pdfs",
  express.static(path.join(__dirname, "uploads/free_pdfs"))
);

app.listen(PORT, () => {
  console.log("✅ Server running on port", PORT);
});
