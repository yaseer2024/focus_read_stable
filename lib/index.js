const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// ✅ SERVE UPLOADS (THIS FIXES PDF OPEN)
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// 🔥 CONFIG ENDPOINT
app.get("/config", (req, res) => {
  res.json({
    apiBaseUrl: process.env.API_BASE_URL || ""
  });
});

// 📚 FREE BOOKS
app.get("/free-books", (req, res) => {
  const baseUrl = process.env.API_BASE_URL;
  const dir = path.join(__dirname, "uploads", "free_pdfs");

  if (!fs.existsSync(dir)) {
    return res.json([]);
  }

  const files = fs.readdirSync(dir).filter(f => f.endsWith(".pdf"));

  res.json(
    files.map((f, index) => ({
      id: index + 1,
      title: f.replace(".pdf", "").replace(/_/g, " "),
      pdfUrl: `${baseUrl}/uploads/free_pdfs/${f}`
    }))
  );
});

// 🏥 HEALTH CHECK
app.get("/", (req, res) => {
  res.send("FocusRead backend running 🚀");
});

app.listen(PORT, () => {
  console.log("Server running on port", PORT);
});
