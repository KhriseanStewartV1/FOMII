import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

interface PushNotificationData {
  title: string;
  body: string;
  token?: string;
  topic?: string;
}

// Send notification to a single device
export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  const { title, body, token } = req.body as PushNotificationData;

  if (!token || !title || !body) {
    res.status(400).send({ success: false, error: "Missing title, body, or token" });
    return;
  }

  const message = {
    notification: { title, body },
    token,
  };

  console.log("sendPushNotification called with:", { title, body, token });

  try {
    const response = await admin.messaging().send(message);
    res.send({ success: true, response });
  } catch (error: any) {
    res.status(500).send({
      success: false,
      error: "Failed to send notification",
      details: error.message || error,
    });
  }
});

// Send notification to a topic
export const sendTopicNotification = functions.https.onRequest(async (req, res) => {
  const { title, body, topic } = req.body as PushNotificationData;

  if (!topic || !title || !body) {
    res.status(400).send({ success: false, error: "Missing title, body, or topic" });
    return;
  }

  const message = {
    notification: { title, body },
    topic,
  };

  console.log("sendTopicNotification called with:", { title, body, topic });

  try {
    const response = await admin.messaging().send(message);
    res.send({ success: true, response });
  } catch (error: any) {
    res.status(500).send({
      success: false,
      error: "Failed to send topic notification",
      details: error.message || error,
    });
  }
});
