import 'package:flutter/material.dart';

class LessonData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final List<Map<String, dynamic>> blocks;

  LessonData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.blue,
    this.xpReward = 100,
    required this.blocks,
  });
}

final List<LessonData> allLessons = [
  LessonData(
    id: 'social-media',
    title: 'Social Media Content Creator',
    description: 'Create posts, captions, and simple graphics for small businesses.',
    icon: Icons.share_rounded,
    color: Colors.pink,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.insights_rounded, 'body': 'Create posts, captions, and simple graphics for small businesses. Businesses need someone to keep their social media active and looking good — and they\'ll pay you to do it.'},
      {'type': 'text_block', 'heading': '1. What is Social Media Management?', 'icon': Icons.hub_rounded, 'body': 'Social media management means running a business\'s social media accounts on their behalf. That can include writing captions, designing graphics, posting content, and sometimes responding to comments.\n\nBusinesses hire people for this because they\'re too busy running their actual business to think about Instagram. Your job is to handle that for them so their page stays active and attractive to customers.'},
      {'type': 'text_block', 'heading': '2. Picking Your Platform', 'icon': Icons.ads_click_rounded, 'body': 'Don\'t try to master every platform at once. Pick one to start:\n\n• Instagram — Great for visual businesses like food, fashion, fitness, and beauty.\n• TikTok — Short-form video content for younger audiences.\n• Facebook — Best for local businesses like restaurants and services.'},
      {'type': 'text_block', 'heading': '3. What Clients Actually Want', 'icon': Icons.groups_rounded, 'body': 'Most small business clients want three things:\n\n- Consistency — posting regularly (3-5 times per week).\n- Professionalism — clean, on-brand visuals.\n- Engagement — content that gets likes, comments, and follows.'},
      {'type': 'text_block', 'heading': '4. How to Write a Good Caption', 'icon': Icons.edit_note_rounded, 'body': 'A good caption does three things:\n\n- Hook: Grabs attention in the first line.\n- Value/Personality: Shares a tip, story, or question.\n- Call to Action: Tells people what to do next (e.g., "Link in bio").'},
      {'type': 'tip_block', 'text': 'Example: "Your Monday just got better. Our sourdough just came out of the oven — golden crust, soft inside, best eaten warm. Come grab a loaf before they\'re gone."'},
      {'type': 'text_block', 'heading': '5. Free Tools: Canva & Later', 'icon': Icons.construction_rounded, 'body': 'Canva: The gold standard for free graphic design. Use templates to match correct dimensions.\n\nLater: A free scheduling tool to automate your posts so you don\'t have to be online 24/7.'},
      {'type': 'text_block', 'heading': '6. Finding Your First Client', 'icon': Icons.search_rounded, 'body': 'Your first client is almost always in your own neighborhood. Try local cafes, salons, or family businesses. Pro Tip: Make 3 sample posts for them BEFORE you reach out. Showing is always better than telling.'},
      {'type': 'text_block', 'heading': '7. What to Charge', 'icon': Icons.monetization_on_rounded, 'body': 'Starters: \$5–\$15 per post.\nMonthly package: \$50–\$150/month for 3 posts per week.\nWith graphics: Add \$5–\$10 per designed graphic.'},
      {'type': 'text_block', 'heading': 'Mini Project', 'icon': Icons.rocket_launch_rounded, 'body': 'Design a 3-post sample for a boutique bakery. Include a graphic from Canva, an engaging caption with a hook, and 5 niche hashtags.'},
      {'type': 'quiz_block', 'questions': [
        'What are the three things most small business clients want?',
        'What are the three parts of a high-performing caption?',
        'Which tools should you use for design and scheduling?',
        'What is the best way to approach a new potential client?',
        'What is a fair monthly rate for 12 posts?'
      ], 'answers': [
        'Consistency, Professionalism, and Engagement.',
        'Hook (Attention), Value/Personality (Body), and Call to Action (the Ask).',
        'Canva for graphic design/visuals and Later for automated scheduling.',
        'Show them 3 high-quality sample posts you made for their specific business first.',
        'Around \$100/month is a standard starting point for 12 posts (approx \$8 per post).'
      ]},
    ],
  ),
  LessonData(
    id: 'logo-design',
    title: 'Logo & Graphic Design',
    description: 'Design simple logos, flyers, and banners using free tools.',
    icon: Icons.brush_rounded,
    color: Colors.orange,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.palette_rounded, 'body': 'Design logos, flyers, and banners. Businesses always need visual assets — and clean design is something they will happily pay for.'},
      {'type': 'text_block', 'heading': '1. Common Design Gigs', 'icon': Icons.layers_rounded, 'body': 'Clients often need:\n- Logos: The visual symbol of the brand.\n- Flyers: For events, sales, or promos.\n- Social Banners: Profile covers for Facebook/LinkedIn.\n- Business Cards: The classic networking tool.'},
      {'type': 'text_block', 'heading': '2. Mastering Canva', 'icon': Icons.auto_fix_high_rounded, 'body': 'Canva is your hub. Focus on learning:\n- Templates: Don\'t start from scratch; customize existing designs.\n- Brand Kit: Keep colors and fonts consistent for each client.\n- Elements: Use shapes and icons to add depth.'},
      {'type': 'text_block', 'heading': '3. Basic Design Rules', 'icon': Icons.rule_rounded, 'body': '- Colors: Stick to 2-3 colors max (Main, Accent, Neutral).\n- Fonts: Use max 2 fonts (1 for headings, 1 for body).\n- Spacing: Use "White Space" to let elements breathe.'},
      {'type': 'text_block', 'heading': '4. File Formats Matter', 'icon': Icons.file_present_rounded, 'body': '- PNG: Use for digital/web (supports transparent backgrounds).\n- PDF: Use for printing (keeps colors sharp and layout intact).\n- JPG: Good for small file sizes without transparency.'},
      {'type': 'text_block', 'heading': '5. Pricing Your Work', 'icon': Icons.payments_rounded, 'body': 'Logo: \$10–\$50 (1-2 revisions)\nFlyer: \$10–\$30\nSocial Banner: \$5–\$20\nBusiness Card: \$10–\$25'},
      {'type': 'text_block', 'heading': 'Mini Project', 'icon': Icons.edit_attributes_rounded, 'body': 'Design a logo for a "Gaming Lounge" or "Dog Walking" company. Use 2 colors, 1 clear font, and export as a transparent PNG.'},
      {'type': 'quiz_block', 'questions': [
        'List three types of common design requests.',
        'What are the 3 fundamental design rules?',
        'Which format is best for a logo with no background?',
        'Which format is best for a flyer meant for printing?',
        'Where can you find your first client locally?'
      ], 'answers': [
        'Logos (brand identity), Flyers (promotions), and Social Media Banners.',
        'Limit colors (2-3), limit fonts (2 max), and use white space (spacing).',
        'PNG (it supports transparent backgrounds).',
        'PDF (it preserves high quality for physical printing).',
        'School clubs, local neighborhood restaurants, or hair salons.'
      ]},
    ],
  ),
  LessonData(
    id: 'video-editing',
    title: 'Video Editing',
    description: 'Edit short videos for YouTubers, TikTokers, or small businesses.',
    icon: Icons.movie_rounded,
    color: Colors.purple,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.video_camera_back_rounded, 'body': 'Edit short videos for creators or businesses. You\'ll turn raw footage into a polished final product.'},
      {'type': 'text_block', 'heading': '1. Video Editing Workflow', 'icon': Icons.history_edu_rounded, 'body': 'The job usually involves:\n- Cutting out mistakes and dead air.\n- Adding royalty-free background music.\n- Adding on-screen text and captions.\n- Exporting in the correct aspect ratio.'},
      {'type': 'text_block', 'heading': '2. Free Editing Tools', 'icon': Icons.construction_rounded, 'body': 'CapCut: The king of mobile/short-form editing (TikTok/Reels).\nDaVinci Resolve: A professional desktop editor available for free.'},
      {'type': 'text_block', 'heading': '3. Basic Edits', 'icon': Icons.content_cut_rounded, 'body': '- Cutting: Ensure there are no long pauses.\n- Audio: Music should be 70% quieter than the speaker.\n- Captions: Vital for viewers watching on "Mute".'},
      {'type': 'text_block', 'heading': '4. Export Settings', 'icon': Icons.ios_share_rounded, 'body': '- YouTube: 1080p, MP4, 30fps (Horizontal).\n- TikTok/Reels: 1080x1920 (Vertical).'},
      {'type': 'text_block', 'heading': '5. Pricing Your Work', 'icon': Icons.euro_rounded, 'body': 'Short-form (<2 min): \$15–\$30\nLong-form YouTube: \$30–\$75\nAd/Promo Spot: \$20–\$50'},
      {'type': 'quiz_block', 'questions': [
        'What are four common editing tasks?',
        'Which tool is best for TikTok editing?',
        'What is the standard vertical video resolution?',
        'Why should you use royalty-free music?',
        'What should you ask a client before starting?'
      ], 'answers': [
        'Cutting mistakes, adding background music, adding captions, and color correction.',
        'CapCut (on mobile or desktop).',
        '1080 x 1920 pixels.',
        'To avoid copyright issues that can get the video taken down.',
        'Platform type, desired length, and if they have a style reference link/video.'
      ]},
    ],
  ),
  LessonData(
    id: 'copywriting',
    title: 'Copywriting & Blog Writing',
    description: 'Write articles, product descriptions, or website text for businesses.',
    icon: Icons.edit_note_rounded,
    color: Colors.blue,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.article_rounded, 'body': 'Write articles, product descriptions, or website text. Businesses need words that sell or inform.'},
      {'type': 'text_block', 'heading': '1. Writing for the Web', 'icon': Icons.laptop_rounded, 'body': 'Web writing is different from school essay writing. Focus on:\n- Short paragraphs (2-3 lines max).\n- Conversational and helpful tone.\n- Clear subheadings for scanning readers.'},
      {'type': 'text_block', 'heading': '2. Blog Post Structure', 'icon': Icons.format_list_numbered_rounded, 'body': '1. Headline: Catchy and descriptive.\n2. Intro: Hook the reader immediately.\n3. Body: Break info into small chunks.\n4. CTA: Tell them what to do at the end.'},
      {'type': 'text_block', 'heading': '3. SEO & Keywords', 'icon': Icons.travel_explore_rounded, 'body': 'SEO (Search Engine Optimization) is using "Keywords" (terms people search for) so Google can find your article and show it to customers.'},
      {'type': 'text_block', 'heading': '4. Pricing Your Work', 'icon': Icons.attach_money_rounded, 'body': 'Short blog (500 words): \$5–\$15\nStandard blog (800 words): \$15–\$35\nProduct description: \$5–\$15'},
      {'type': 'quiz_block', 'questions': [
        'How is web writing different from school writing?',
        'What are the 5 parts of a blog post?',
        'What does SEO stand for?',
        'What tool helps check for grammar errors?',
        'What is a fair price for an 800-word blog?'
      ], 'answers': [
        'Web writing uses shorter paragraphs, simpler words, and a conversational tone.',
        'Headline, Introduction, Subheadings, Body sections, and a Conclusion/CTA.',
        'Search Engine Optimization (making content rank on Google).',
        'Grammarly.',
        'Between \$15 and \$35 is a fair starter rate for that length.'
      ]},
    ],
  ),
  LessonData(
    id: 'photo-editing',
    title: 'Photo Editing & Retouching',
    description: 'Edit photos for individuals, families, or small business owners.',
    icon: Icons.camera_rounded,
    color: Colors.teal,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.auto_fix_normal_rounded, 'body': 'Edit photos for product owners or families. You\'ll make their images look polished and professional.'},
      {'type': 'text_block', 'heading': '1. Photo Editing Tasks', 'icon': Icons.tune_rounded, 'body': 'Requests usually include:\n- Adjusting brightness and contrast.\n- Removing backgrounds for products.\n- Blemish removal for portraits.\n- Color correction for indoor lighting.'},
      {'type': 'text_block', 'heading': '2. Free Tools', 'icon': Icons.construction_rounded, 'body': 'Snapseed: Great for quick mobile edits.\nPhotopea: A browser-based Photoshop clone for background removal.'},
      {'type': 'text_block', 'heading': '3. File Delivery', 'icon': Icons.cloud_download_rounded, 'body': 'JPEGs for standard viewing. PNGs for transparent background product shots.'},
      {'type': 'text_block', 'heading': '4. Pricing Your Work', 'icon': Icons.wallet_rounded, 'body': 'Basic Edit: \$3–\$8 per photo\nBackground Removal: \$5–\$15 per photo\nRetouching: \$10–\$25 per photo'},
      {'type': 'quiz_block', 'questions': [
        'Name three typical editing requests.',
        'Which tool is best for background removal?',
        'When should you use PNG format?',
        'How should you deliver many photos at once?',
        'What is a fair price for background removal?'
      ], 'answers': [
        'Adjusting brightness/contrast, blemish removal, and background removal.',
        'Photopea or Remove.bg.',
        'When you need to keep the background transparent (e.g. for product mockups).',
        'Upload to a Google Drive or Dropbox folder and share the link.',
        '\$5 to \$15 per photo based on how complex the product is.'
      ]},
    ],
  ),
  LessonData(
    id: 'data-entry',
    title: 'Data Entry & Online Research',
    description: 'Help businesses organize information or research topics online.',
    icon: Icons.analytics_rounded,
    color: Colors.indigo,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.table_chart_rounded, 'body': 'Help businesses build spreadsheets and find info. Accuracy is your most valuable skill here.'},
      {'type': 'text_block', 'heading': '1. Data vs Research', 'icon': Icons.find_in_page_rounded, 'body': 'Data Entry: Moving info into a structured format (e.g., typing names into a sheet).\nResearch: Finding new info (e.g., finding local pet shop emails).'},
      {'type': 'text_block', 'heading': '2. Tool: Google Sheets', 'icon': Icons.view_quilt_rounded, 'body': 'The core tool for data work. Learn to use columns, filters, and standard formatting for dates and phones.'},
      {'type': 'text_block', 'heading': '3. Pricing Your Work', 'icon': Icons.credit_card_rounded, 'body': 'Hourly: \$8–\$15 per hour.\nFlat project rate: Estimate the total time and quote a fixed fee.'},
      {'type': 'quiz_block', 'questions': [
        'What is the difference between data entry and research?',
        'What are the 4 rules for organizing data?',
        'How do you search for exact phrases on Google?',
        'Why is accuracy critical in data entry?',
        'How do you calculate a flat project fee?'
      ], 'answers': [
        'Data entry is organizing existing information; online research is finding new data.',
        'Consistent formatting, one item per cell, clear column headers, and no blank rows.',
        'Surround the phrase with double quotation marks " ".',
        'One mistake (like a wrong email) can cause an entire order or mailing to fail.',
        'Estimate total hours (e.g. 4 hrs) and multiply by your hourly rate (e.g. \$10) = \$40.'
      ]},
    ],
  ),
  LessonData(
    id: 'tutoring',
    title: 'Tutoring & Online Teaching',
    description: 'Teach other students subjects you\'re good at over video call.',
    icon: Icons.school_rounded,
    color: Colors.amber,
    blocks: [
      {'type': 'text_block', 'heading': 'What You\'ll Do', 'icon': Icons.person_search_rounded, 'body': 'Teach subjects you excel in to younger students. You only need to be 1-2 grade levels ahead.'},
      {'type': 'text_block', 'heading': '1. Running a Session', 'icon': Icons.record_voice_over_rounded, 'body': 'Briefly explain the concept, work through an example together, and then let the student lead while you provide guidance.'},
      {'type': 'text_block', 'heading': '2. Explaining Clearly', 'icon': Icons.light_mode_rounded, 'body': '- Use examples before rules: Solve a problem first.\n- Use analogies: Connect history or math to real-world things they know.'},
      {'type': 'text_block', 'heading': '3. Pricing Your Work', 'icon': Icons.local_atm_rounded, 'body': 'Elementary: \$10–\$15/hr\nMiddle School: \$12–\$18/hr\nHigh School: \$15–\$25/hr'},
      {'type': 'quiz_block', 'questions': [
        'What should you do to prepare for a session?',
        'Name two techniques for clear explanations.',
        'Why offer a free 15-minute intro?',
        'What do you do if a student doesn\'t understand?',
        'Where can you find your first student?'
      ], 'answers': [
        'Ask what they specifically need help with, review the topic, and prepare example problems.',
        'Use examples before rules and use analogies.',
        'To let the student and parent see if you are a good fit without any risk.',
        'Try a completely different approach, analogy, or a simpler breakdown.',
        'School community boards, local parent Facebook groups, or the Wyzant platform.'
      ]},
    ],
  ),
];
