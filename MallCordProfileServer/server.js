import express from "express";
import cors from "cors";
import fs from "fs";

const app = express();
const PORT = process.env.PORT || 3000;
const DB_FILE = "./profiles.json";
const API_KEY = "mallcord-secret-key";

app.use(cors());
app.use(express.json({ limit: "10mb" }));

function readProfiles() {
    if (!fs.existsSync(DB_FILE)) fs.writeFileSync(DB_FILE, "{}");
    return JSON.parse(fs.readFileSync(DB_FILE, "utf8"));
}

function saveProfiles(data) {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 4));
}

app.get("/profiles", (req, res) => {
    res.json(readProfiles());
});

app.post("/profiles/:userId", (req, res) => {
    const key = req.headers.authorization;

    if (key !== API_KEY) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const profiles = readProfiles();

    profiles[req.params.userId] = {
        ...req.body,
        updatedAt: Date.now()
    };

    saveProfiles(profiles);

    res.json({
        ok: true,
        userId: req.params.userId,
        profile: profiles[req.params.userId]
    });
});

app.delete("/profiles/:userId", (req, res) => {
    const key = req.headers.authorization;

    if (key !== API_KEY) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const profiles = readProfiles();
    delete profiles[req.params.userId];
    saveProfiles(profiles);

    res.json({ ok: true });
});

app.listen(PORT, () => {
    console.log(`MallCord profile server running on port ${PORT}`);
});
