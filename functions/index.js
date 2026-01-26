/**
 * GitHub Wallpaper - Cloud Scheduler Function
 * Triggers a silent push notification to all subscribed devices daily.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Schedule: Every 15 minutes for testing (Original: "every day 00:00")
// Timezone: America/New_York (or UTC, user preference)
exports.triggerDailyUpdate = functions.pubsub
    .schedule("every 15 minutes")
    .timeZone("UTC") // Default to UTC
    .onRun(async (context) => {
        console.log("⏰ Daily Update Triggered");

        // "Silent Push" Payload
        // Just a data message, NO 'notification' key (which would show UI)
        const payload = {
            data: {
                type: "daily_refresh",
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: "high",
                ttl: 3600 * 1000, // 1 hour
            },
            topic: "daily-updates",
        };

        let attempts = 0;
        const maxAttempts = 3;
        let lastError;

        while (attempts < maxAttempts) {
            try {
                // Send to 'daily-updates' topic
                const response = await admin.messaging().send(payload);
                console.log(`✅ Successfully sent update message (Attempt ${attempts + 1}):`, response);
                return null;
            } catch (error) {
                attempts++;
                lastError = error;
                console.error(`⚠️ Attempt ${attempts} failed:`, error);
                if (attempts < maxAttempts) {
                    // Wait 500ms before retrying
                    await new Promise(resolve => setTimeout(resolve, 500));
                }
            }
        }

        console.error("❌ All attempts failed. Last error:", lastError);
        return null;
    });
