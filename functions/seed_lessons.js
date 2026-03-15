const admin = require('firebase-admin');

// Ensure we don't initialize the app twice if the script is run in an environment that might preserve state
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

async function seed() {
  try {
    const lessons = [
      {
        title: "How to Introduce Yourself (Professionalism)",
        duration: "5 min",
        trackId: "prof",
        xpReward: 100,
        blocks: [
          { 
            type: "text_block", 
            heading: "First Impressions", 
            body: "When you meet a client, smile and make eye contact. A firm handshake and a clear introduction set the tone for a professional relationship." 
          },
          { 
            type: "tip_block", 
            text: "Arrive 5 minutes early to show you are reliable and respect the client's time." 
          },
          { 
            type: "quiz_block", 
            question: "What should you do if you are running late?", 
            options: ["Don't say anything", "Text the client immediately", "Cancel the job"], 
            correctIndex: 1, 
            explanation: "Communication is key. Most clients are understanding if you let them know early." 
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Lawn Mowing Safety (Lawn & Outdoor)",
        duration: "8 min",
        trackId: "outdoor",
        xpReward: 150,
        blocks: [
          { 
            type: "checklist_block", 
            title: "Before You Start", 
            items: ["Wear closed-toe shoes", "Clear the lawn of rocks, toys, and debris", "Check fuel and oil levels"] 
          },
          { 
            type: "text_block", 
            heading: "The Perimeter Cut", 
            body: "Start by mowing the edges of the yard first. This gives you a clear boundary and makes turning easier." 
          },
          { 
            type: "tip_block", 
            text: "Never pull the mower backward unless absolutely necessary." 
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Babysitting 101: Engaging Kids (Childcare)",
        duration: "10 min",
        trackId: "childcare",
        xpReward: 150,
        blocks: [
          {
            type: "text_block",
            heading: "Being Proactive",
            body: "Don't just watch the kids—engage with them. Bring age-appropriate games, books, or crafts to be their favorite sitter."
          },
          {
            type: "tip_block",
            text: "Always ask parents about allergies, bedtime routines, and emergency contacts before they leave."
          },
          {
            type: "quiz_block",
            question: "What should you do if a child throws a tantrum?",
            options: ["Yell back", "Ignore them completely", "Stay calm and redirect their attention"],
            correctIndex: 2,
            explanation: "Staying calm helps de-escalate. Redirecting their attention to a new activity often resolves the tantrum."
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Effective Tutoring Habits (Tutoring & Teaching)",
        duration: "7 min",
        trackId: "tutoring",
        xpReward: 120,
        blocks: [
          {
            type: "text_block",
            heading: "Patience and Encouragement",
            body: "Tutoring isn't just about giving the right answers. It's about guiding your student to find the answer themselves. Ask leading questions and praise effort."
          },
          {
            type: "checklist_block",
            title: "Tutoring Session Prep",
            items: ["Review the subject material ahead of time", "Prepare 2-3 practice problems", "Bring visual aids if helpful"]
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Designing for Clients (Creative & Design)",
        duration: "10 min",
        trackId: "creative",
        xpReward: 130,
        blocks: [
          {
            type: "text_block",
            heading: "Understanding the Brief",
            body: "Before you start designing, ask the client clear questions about their brand, target audience, and preferred colors. Clear communication prevents multiple revisions."
          },
          {
            type: "tip_block",
            text: "Always send drafts with a watermark or in a lower resolution until final payment is received."
          },
          {
            type: "quiz_block",
            question: "What is a 'revision cycle'?",
            options: ["Designing everything from scratch", "A round of changes based on client feedback", "Adding circles to the design"],
            correctIndex: 1,
            explanation: "A revision cycle is when the client reviews your work and asks for specific changes. Limit these in your contract!"
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Tech Support Basics (Tech & Digital)",
        duration: "6 min",
        trackId: "tech",
        xpReward: 110,
        blocks: [
          {
            type: "text_block",
            heading: "The Golden Rule of Tech Support",
            body: "Always start with the simplest solution: Have you tried turning it off and on again? Restarting solves surprisingly many issues."
          },
          {
            type: "checklist_block",
            title: "Remote Support Checklist",
            items: ["Ask the user to describe exactly what happens", "Check internet connection", "Ensure the device is plugged in or charged"]
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Understanding Your Earnings (Money & Finance)",
        duration: "8 min",
        trackId: "money",
        xpReward: 140,
        blocks: [
          {
            type: "text_block",
            heading: "Saving vs. Spending",
            body: "When you get paid, try the 50/30/20 rule: 50% for needs, 30% for wants, and 20% to savings. Even small savings add up over time."
          },
          {
            type: "tip_block",
            text: "Keep a ledger (or a spreadsheet) of all your jobs and earnings. This helps if you ever need to track your income for taxes."
          },
          {
            type: "quiz_block",
            question: "Why should you save a portion of your income?",
            options: ["To buy everything immediately", "For long-term goals and emergencies", "Because it is required by law"],
            correctIndex: 1,
            explanation: "An emergency fund and long-term savings protect you and help you achieve larger goals like buying a car."
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        title: "Staying Safe on Jobs (Safety & Contracts)",
        duration: "12 min",
        trackId: "safety",
        xpReward: 200,
        blocks: [
          {
            type: "text_block",
            heading: "Stranger Safety",
            body: "Never meet a client for the first time without telling a parent or guardian exactly where you are going and when you will be back. If you feel unsafe, leave immediately."
          },
          {
            type: "checklist_block",
            title: "Safety Must-Dos",
            items: ["Share location with a parent", "Keep your phone charged", "Communicate exclusively through the Rodo app before arriving"]
          },
          {
            type: "tip_block",
            text: "A verbal agreement is a contract. Always re-confirm the pay and the specific tasks before starting work to avoid misunderstandings."
          }
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    for (const lesson of lessons) {
      await db.collection('lessons').add(lesson);
    }
    console.log(`Successfully seeded ${lessons.length} lessons`);
    process.exit(0);
  } catch (error) {
    console.error('Seed failed:', error);
    process.exit(1);
  }
}

seed();
