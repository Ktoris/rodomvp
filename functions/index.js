const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Helper: Create Notification
async function createNotification(uid, type, title, body, relatedId = null) {
    return admin.firestore()
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
            type: type,
            title: title,
            body: body,
            relatedId: relatedId,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
}

// 1. Init Teen User schema
exports.onUserCreate = functions.firestore.document("users/{uid}").onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.role === 'teen') {
        return snap.ref.set({
           stats: {
               jobsDone: 0,
               totalEarned: 0,
               lessonsCompleted: 0,
               repeatHires: 0,
               avgRating: 0.0,
               totalReviews: 0
           },
           badges: [],
           skills: [],
           portfolio: [],
           discoveryScore: 0
        }, { merge: true });
    }
    return null;
});

// 2. Generate Parent Approval Token once email is verified
exports.onTeenEmailVerified = functions.firestore.document("users/{uid}").onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    const uid = context.params.uid;

    if (before.verified === false && after.verified === true && after.role === 'teen' && after.parentEmail) {
        const crypto = require('crypto');
        const token = crypto.randomBytes(20).toString('hex');
        
        await admin.firestore().collection('parentApprovals').doc(token).set({
            teenUid: uid,
            parentEmail: after.parentEmail,
            expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 72 * 60 * 60 * 1000)),
            status: 'pending'
        });

        console.log(`[EMAIL SIMULATION] Sending parent approval to ${after.parentEmail}`);
        
        return change.after.ref.update({
             accountStatus: 'pending_parent'
        });
    }
    return null;
});

// 3. Parent verifies account
exports.approveTeenAccount = functions.https.onCall(async (data, context) => {
    const token = data.token;
    if (!token) throw new functions.https.HttpsError('invalid-argument', 'Missing token');

    const approvalRef = admin.firestore().collection('parentApprovals').doc(token);
    const approvalDoc = await approvalRef.get();

    if (!approvalDoc.exists) throw new functions.https.HttpsError('not-found', 'Invalid token');

    const approvalData = approvalDoc.data();
    if (approvalData.expiresAt.toDate() < new Date()) {
        throw new functions.https.HttpsError('failed-precondition', 'Token expired');
    }

    if (approvalData.status === 'active') {
        throw new functions.https.HttpsError('already-exists', 'Already approved');
    }

    const batch = admin.firestore().batch();
    batch.update(approvalRef, { status: 'active' });
    
    const teenRef = admin.firestore().collection('users').doc(approvalData.teenUid);
    batch.update(teenRef, { accountStatus: 'active' });

    await batch.commit();

    // Notify Teen
    await createNotification(
        approvalData.teenUid, 
        'account_approved', 
        'Account Approved!', 
        'Your parent has approved your account. You can now start earning!'
    );

    return { success: true, message: 'Teen account activated' };
});

// 4. Job Offer Notification
exports.onHireRequestCreate = functions.firestore.document("hire_requests/{requestId}").onCreate(async (snap, context) => {
    const data = snap.data();
    return createNotification(
        data.teenId, 
        'job_offer', 
        'New Job Offer!', 
        `You have a new offer from ${data.adultName}: ${data.jobTitle}`,
        context.params.requestId
    );
});

// 5. Job Status Change Notification
exports.onHireRequestUpdate = functions.firestore.document("hire_requests/{requestId}").onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();

    // Handled Acceptance
    if (before.status === 'pending' && after.status === 'accepted') {
        return createNotification(
            after.adultId, 
            'job_accepted', 
            'Job Accepted!', 
            `A teen has accepted your request: ${after.jobTitle}`,
            context.params.requestId
        );
    }

    if (before.status !== 'completed' && after.status === 'completed') {
        const teenId = after.teenId;
        const userRef = admin.firestore().collection("users").doc(teenId);
        
        await admin.firestore().runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) return;
            const stats = userDoc.data().stats || {};
            transaction.update(userRef, {
                'stats.jobsDone': (stats.jobsDone || 0) + 1
            });
        });

        await createNotification(
            after.adultId, 
            'job_completed', 
            'Job Completed!', 
            `Your job "${after.jobTitle}" is done. Please leave a review!`,
            context.params.requestId
        );

        return checkBadgeUnlocks(teenId);
    }

    return null;
});

// 6. Chat Message Notification
exports.onChatMessageCreate = functions.firestore.document("chats/{chatId}/messages/{msgId}").onCreate(async (snap, context) => {
    const data = snap.data();
    const chatId = context.params.chatId;

    // Get the chat doc to find the other participant
    const chatSnap = await admin.firestore().collection('chats').doc(chatId).get();
    const chatData = chatSnap.data();
    
    // Recipient is the one WHO IS NOT the sender
    const recipientId = (data.senderId === chatData.teenId) ? chatData.adultId : chatData.teenId;

    return createNotification(
        recipientId, 
        'new_message', 
        'New Message', 
        data.text || 'Shared an image',
        chatId
    );
});

// 7. Support Ticket Confirmation
exports.onSupportTicketCreate = functions.firestore.document("support/{ticketId}").onCreate(async (snap, context) => {
    const data = snap.data();
    const ticketId = context.params.ticketId;

    console.log(`[EMAIL SIMULATION] Sending support confirmation to ${data.email}`);
    console.log(`[EMAIL SIMULATION] Ticket ID: ${ticketId}`);
    
    // In a real app, you'd use a mail provider here.
    return null;
});

// 8. Geocode Teen City
exports.geocodeTeenCity = functions.firestore.document("users/{uid}").onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();

    if (after.role === 'teen' && after.city && after.city !== before.city) {
        // Simulated Geocoding
        // In production: use Google Maps Geocoding API
        const cityCoords = {
            'new york': { lat: 40.7128, lng: -74.0060 },
            'los angeles': { lat: 34.0522, lng: -118.2437 },
            'chicago': { lat: 41.8781, lng: -87.6298 },
            'houston': { lat: 29.7604, lng: -95.3698 },
            'phoenix': { lat: 33.4484, lng: -112.0740 },
        };

        const city = after.city.toLowerCase();
        const coords = cityCoords[city] || { 
            lat: 40.0 + (Math.random() * 10), 
            lng: -100.0 + (Math.random() * 20) 
        };

        return change.after.ref.set({
            location: {
                city: after.city,
                lat: coords.lat,
                lng: coords.lng
            }
        }, { merge: true });
    }
    return null;
});

// 9. Update Discovery Scores (Scheduled)
exports.updateDiscoveryScores = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const teens = await admin.firestore().collection('users')
        .where('role', '==', 'teen')
        .where('accountStatus', '==', 'active')
        .get();

    const batch = admin.firestore().batch();

    teens.docs.forEach((doc) => {
        const data = doc.data();
        const stats = data.stats || {};
        const avgRating = (data.avgRating || data.rating || 0);
        const jobsDone = (stats.jobsDone || 0);
        const repeatHires = (stats.repeatHires || 0);

        // Score = (avgRating * 20) + (jobsDone * 2) + (repeatHires * 5)
        const score = (avgRating * 20) + (jobsDone * 2) + (repeatHires * 5);

        batch.update(doc.ref, { discoveryScore: score });
    });

    return batch.commit();
});

// 10. Lesson Complete Trigger
exports.onLessonComplete = functions.firestore.document("users/{uid}/lessonProgress/{lessonId}").onCreate(async (snap, context) => {
    const uid = context.params.uid;
    const data = snap.data();
    const xpEarned = data.xpEarned || 50;

    const userRef = admin.firestore().collection("users").doc(uid);
    
    await admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        const currentStats = userDoc.data().stats || {};
        const newStats = {
            ...currentStats,
            lessonsCompleted: (currentStats.lessonsCompleted || 0) + 1,
            xp: (currentStats.xp || 0) + xpEarned
        };

        transaction.update(userRef, { stats: newStats });
    });

    return checkBadgeUnlocks(uid);
});

// 11. Expire Job Offers (Scheduled)
exports.expireJobOffers = functions.pubsub.schedule('every hour').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const fortyEightHoursAgo = new Date(now.toDate().getTime() - (48 * 60 * 60 * 1000));

    const expiredRequests = await admin.firestore().collection('hire_requests')
        .where('status', 'in', ['pending', 'ignored'])
        .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(fortyEightHoursAgo))
        .get();

    const batch = admin.firestore().batch();
    expiredRequests.docs.forEach((doc) => {
        batch.update(doc.ref, { status: 'expired' });
    });

    return batch.commit();
});

// 12. Helper: Check and Award Badges
async function checkBadgeUnlocks(uid) {
    const userRef = admin.firestore().collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const stats = userData.stats || {};
    const currentBadges = userData.badges || [];
    const avgRating = userData.avgRating || 0;
    const reviewCount = userData.reviewCount || 0;

    const newBadges = [...currentBadges];
    let changed = false;

    // Badge Logic
    const addBadge = (badgeId) => {
        if (!newBadges.includes(badgeId)) {
            newBadges.push(badgeId);
            changed = true;
            console.log(`[BADGE] Awarded ${badgeId} to ${uid}`);
        }
    };

    if (stats.jobsDone >= 1) addBadge('first_job');
    if (stats.jobsDone >= 5) addBadge('jobs_5');
    if (stats.jobsDone >= 10) addBadge('jobs_10');
    if (stats.lessonsCompleted >= 1) addBadge('first_lesson');
    if (stats.lessonsCompleted >= 5) addBadge('lesson_grad');
    if (avgRating >= 4.8 && reviewCount >= 5) addBadge('top_rated');

    if (changed) {
        await userRef.update({ badges: newBadges });
        // Create a notification for the badge
        try {
            await admin.firestore().collection('notifications').doc(uid).collection('items').add({
                type: 'badge_earned',
                title: 'New Badge Earned!',
                body: 'Congratulations! You earned a new badge. Check your profile.',
                relatedId: 'badges',
                read: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        } catch (err) {
            console.error('Failed to create notification', err);
        }
    }
}

// 13. Review Creation Trigger
exports.onReviewCreate = functions.firestore.document("reviews/{jobId}").onCreate(async (snap, context) => {
    const data = snap.data();
    const teenId = data.revieweeUid;

    const userRef = admin.firestore().collection("users").doc(teenId);
    
    await admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        const currentRating = userDoc.data().avgRating || 0;
        const currentCount = userDoc.data().reviewCount || 0;
        
        const newCount = currentCount + 1;
        const newRating = ((currentRating * currentCount) + data.rating) / newCount;

        transaction.update(userRef, {
            avgRating: newRating,
            reviewCount: newCount
        });
    });

    return checkBadgeUnlocks(teenId);
});
