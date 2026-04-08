const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { TranslationServiceClient } = require("@google-cloud/translate").v3;

const client = new TranslationServiceClient();

exports.translateText = onCall({ region: "us-central1" }, async (request) => {
  const { texts, targetLanguage } = request.data || {};

  if (!Array.isArray(texts) || texts.length === 0) {
    throw new HttpsError("invalid-argument", "A non-empty texts array is required.");
  }

  if (!targetLanguage || typeof targetLanguage !== "string") {
    throw new HttpsError("invalid-argument", "A valid targetLanguage is required.");
  }

  try {
    const projectId = process.env.GCLOUD_PROJECT;

    const safeTexts = texts.map((text) =>
      typeof text === "string" && text.trim().length > 0 ? text : ""
    );

    const [response] = await client.translateText({
      parent: `projects/${projectId}/locations/global`,
      contents: safeTexts,
      mimeType: "text/plain",
      targetLanguageCode: targetLanguage,
    });

    const translatedTexts = safeTexts.map((original, index) => {
      const translated = response.translations?.[index]?.translatedText;
      return translated || original;
    });

    return { translatedTexts };
  } catch (error) {
    logger.error("Translation error:", error);
    throw new HttpsError("internal", "Translation failed.");
  }
});