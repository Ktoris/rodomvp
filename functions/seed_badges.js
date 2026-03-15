const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

async function seedBadges() {
  const badges = [
    {
      id: 'first_job',
      name: 'First Job',
      description: 'Completed your very first job on Rodo!',
      icon: 'stars'
    },
    {
      id: 'jobs_5',
      name: 'High Five',
      description: 'Completed 5 jobs!',
      icon: 'thumb_up'
    },
    {
      id: 'jobs_10',
      name: 'Decathlete',
      description: 'Completed 10 jobs!',
      icon: 'workspace_premium'
    },
    {
      id: 'top_rated',
      name: 'Top Rated',
      description: 'Maintained a 4.8+ star rating with at least 5 reviews.',
      icon: 'verified'
    },
    {
      id: 'first_lesson',
      name: 'Fresh Learner',
      description: 'Completed your first skill-building lesson!',
      icon: 'school'
    },
    {
      id: 'lesson_grad',
      name: 'Scholar',
      description: 'Completed 5 lessons!',
      icon: 'auto_stories'
    }
  ];

  const batch = db.batch();
  badges.forEach(badge => {
    const ref = db.collection('badges').doc(badge.id);
    batch.set(ref, badge);
  });

  await batch.commit();
  console.log('Successfully seeded 6 badges');
  process.exit(0);
}

seedBadges().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
