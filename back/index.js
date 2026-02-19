const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2/promise");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const app = express();
app.use(bodyParser.json());

const REGION = process.env.AWS_REGION || "us-east-1";
const snsClient = new SNSClient({ region: REGION });
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER || process.env.DB_USERNAME,
  password: process.env.DB_PASS || process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: Number(process.env.DB_PORT || 3306),
};

app.get("/health", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

app.get("/api/health", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

const createTask = async (req, res) => {
  const { title, description, courseId, createdBy } = req.body;

  if (!title || !createdBy) {
    return res.status(400).json({ error: "title y createdBy son requeridos" });
  }

  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      "INSERT INTO tasks (title, description, course_id, created_by, created_at) VALUES (?, ?, ?, ?, NOW())",
      [title, description || "", courseId || null, createdBy]
    );
    await connection.end();

    if (SNS_TOPIC_ARN) {
      await snsClient.send(
        new PublishCommand({
          TopicArn: SNS_TOPIC_ARN,
          Message: `Tarea creada: ${title}`,
          Subject: "Nueva tarea creada",
        })
      );
    }

    return res.json({
      taskId: result.insertId,
      message: SNS_TOPIC_ARN ? "Task creada y notificacion enviada" : "Task creada",
    });
  } catch (err) {
    console.error("Error:", err);
    return res.status(500).json({ error: "internal error", details: err.message });
  }
};

app.post("/tasks", createTask);
app.post("/api/tasks", createTask);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend corriendo en puerto ${PORT}`));
