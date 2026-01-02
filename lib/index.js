const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const multer = require("multer");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 📂 Ensure upload directory exists
const uploadDir = path.join(__dirname, "uploads/free_pdfs");
fs.mkdirSync(uploadDir, { recursive: true });

// 🔥 MULTER STORAGE
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  }
});

const upload = multer({ storage });

// 🔥 CONFIG ENDPOINT
app.get("/config", (req, res) => {
  const baseUrl = req.protocol + "://" + req.get("host");
  res.json({ apiBaseUrl: baseUrl });
});

// 📚 FREE BOOKS LIST
app.get("/free-books", (req, res) => {
  const files = fs
    .readdirSync(uploadDir)
    .filter(f => f.toLowerCase().endsWith(".pdf"));

  res.json(
    files.map(f => ({
      id: f,
      title: f.replace(".pdf", "")
    }))
  );
});

// ⬆️ UPLOAD PDF
app.post("/upload", upload.single("pdf"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded" });
  }

  res.json({
    success: true,
    file: req.file.originalname
  });
});

// 📄 SERVE PDFs (BOTH PATHS)
app.use("/free_pdfs", express.static(uploadDir));
app.use("/uploads/free_pdfs", express.static(uploadDir));

app.listen(PORT, () => {
  console.log("✅ Server running on port", PORT);
});
