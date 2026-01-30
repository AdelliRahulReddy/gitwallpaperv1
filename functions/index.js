/**
 * GitHub Wallpaper - Cloud Scheduler Function
 * Triggers a silent push notification to all subscribed devices.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Schedule: Every 5 minutes
// Timezone: UTC
exports.triggerDailyUpdate = functions.pubsub
    .schedule("every 5 minutes")
    .timeZone("UTC")
    .onRun(async (context) => {
        console.log("⏰ Daily Update Triggered");

        // Build message payload
        const message = {
            data: {
                type: "daily_refresh",
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: "high",
                ttl: 3600 * 1000, // 1 hour
            },
            topic: "daily-updates", // ✅ Correct placement
        };

        let attempts = 0;
        const maxAttempts = 3;
        let lastError;

        while (attempts < maxAttempts) {
            try {
                // Send to 'daily-updates' topic
                const response = await admin.messaging().send(message);
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
