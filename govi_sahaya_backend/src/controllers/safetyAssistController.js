// controllers/safetyAssistController.js

const axios = require('axios');
const logger = require('../utils/logger');
const { HTTP_STATUS } = require('../config/constants');

// ── Static emergency contacts (Sri Lanka) ─────────────────────────────
const EMERGENCY_CONTACTS = [
  { id: '1', name: 'Police Emergency',     nameSi: 'පොලිස් හදිසි',          nameTa: 'காவல் அவசரகாலம்',    number: '119',  category: 'police',      color: '#1565C0' },
  { id: '2', name: 'Ambulance',            nameSi: 'ගිලන් රථ',              nameTa: 'ஆம்புலன்ஸ்',          number: '1990', category: 'medical',     color: '#C62828' },
  { id: '3', name: 'Fire & Rescue',        nameSi: 'ගිනි නිවීම',            nameTa: 'தீயணைப்பு',           number: '110',  category: 'fire',        color: '#E65100' },
  { id: '4', name: 'Agriculture Hotline',  nameSi: 'කෘෂිකර්ම හොට්ලයින්',   nameTa: 'விவசாய ஹாட்லைன்',    number: '1920', category: 'agriculture', color: '#2E7D32' },
  { id: '5', name: 'Disaster Management', nameSi: 'ආපදා කළමනාකරණ',        nameTa: 'பேரிடர் மேலாண்மை',   number: '117',  category: 'disaster',    color: '#6A1B9A' },
  { id: '6', name: 'Poison Information',  nameSi: 'විෂ තොරතුරු',           nameTa: 'விஷ தகவல்',           number: '0112686143', category: 'poison', color: '#AD1457' },
];

// ── Static first aid guides ────────────────────────────────────────────
const FIRST_AID_GUIDES = [
  {
    id: '1',
    title: 'Snake Bite',
    titleSi: 'සර්ප දෂ්ටනය',
    titleTa: 'பாம்பு கடி',
    icon: 'warning',
    color: '#C62828',
    category: 'animal',
    symptoms: [
      'Two puncture marks at bite site',
      'Swelling and redness',
      'Nausea or vomiting',
      'Blurred vision or dizziness',
    ],
    symptomsSi: ['දෂ්ට ස්ථානයේ සිදුරු දෙකක්', 'ඉදිමීම සහ රතු පැහැය', 'ඔක්කාරය', 'අක්ෂි බොදු වීම'],
    symptomsTa: ['கடிபட்ட இடத்தில் இரு துளைகள்', 'வீக்கம் மற்றும் சிவப்பு', 'குமட்டல்', 'மங்கலான பார்வை'],
    steps: [
      'Keep the victim calm and still',
      'Immobilize the affected limb below heart level',
      'Remove rings or tight clothing near the bite',
      'Mark the edge of swelling with a pen and note the time',
      'Call 1990 or get to hospital immediately',
      'Do NOT cut the wound or suck the venom',
    ],
    stepsSi: ['රෝගියා සන්සුන්ව තබා ගන්න', 'හදවතට පහළින් අත/පය ස්ථාවරව තබන්න', 'මුදු හෝ තද ඇඳුම් ඉවත් කරන්න', 'ඉදිමීමේ කෙළවර සලකුණු කරන්න', '1990 අමතන්න', 'තුවාල කැපීමෙන් හෝ විෂ빨ීමෙන් වළකින්න'],
    stepsTa: ['நோயாளியை அமைதியாக வையுங்கள்', 'பாதிக்கப்பட்ட உறுப்பை இதயத்திற்கு கீழே வையுங்கள்', 'மோதிரங்கள் நீக்கவும்', 'வீக்கத்தின் விளிம்பை குறிக்கவும்', '1990 அழைக்கவும்', 'காயத்தை வெட்டாதீர்கள்'],
    doNot: ['Do NOT apply tourniquet', 'Do NOT cut the wound', 'Do NOT suck the venom', 'Do NOT apply ice'],
    doNotSi: ['ටෝනිකෙට් නොගන්න', 'තුවාල නොකපන්න', 'විෂ නොබොන්න', 'අයිස් නොතබන්න'],
    doNotTa: ['தொனிக்கட் பயன்படுத்தாதீர்கள்', 'காயத்தை வெட்டாதீர்கள்', 'விஷத்தை உறிஞ்சாதீர்கள்', 'பனி வைக்காதீர்கள்'],
  },
  {
    id: '2',
    title: 'Pesticide Poisoning',
    titleSi: 'පළිබෝධනාශක විෂ වීම',
    titleTa: 'பூச்சிக்கொல்லி நச்சு',
    icon: 'science',
    color: '#6A1B9A',
    category: 'chemical',
    symptoms: ['Excessive sweating', 'Nausea and vomiting', 'Blurred vision', 'Muscle twitching', 'Difficulty breathing'],
    symptomsSi: ['අධික දහදිය', 'ඔක්කාරය', 'ඇස් බොදු වීම', 'මාංශ පේශී කැකෑරීම', 'හුස්ම ගැනීමේ අපහසුව'],
    symptomsTa: ['அதிக வியர்வை', 'குமட்டல்', 'மங்கலான பார்வை', 'தசை இழுப்பு', 'சுவாசிக்க சிரமம்'],
    steps: [
      'Move victim to fresh air immediately',
      'Remove contaminated clothing carefully',
      'Wash skin with soap and water for 15 minutes',
      'If swallowed, do NOT induce vomiting',
      'Call poison control: 0112686143',
      'Bring pesticide container to hospital',
    ],
    stepsSi: ['ගොදුරු නැවුම් වාතයට ගෙනයන්න', 'දූෂිත ඇඳුම් ඉවත් කරන්න', 'සබන් වතුරෙන් හමීනට ළෙවකන්න', 'ගිලිඳ නම් වමනය ඇති නොකරන්න', 'විෂ තොරතුරු: 0112686143', 'ස්ථාන බෝතලය රෝහලට ගෙනයන්න'],
    stepsTa: ['உடனே சுத்தமான காற்றுக்கு அழைத்துச் செல்லுங்கள்', 'மாசுபட்ட ஆடைகளை கவனமாக அகற்றவும்', 'சோப்பு தண்ணீரால் 15 நிமிடம் கழுவவும்', 'விழுங்கியிருந்தால் வாந்தி எடுக்காதீர்கள்', 'விஷ கட்டுப்பாடு: 0112686143', 'பூச்சிக்கொல்லி டப்பாவை மருத்துவமனைக்கு கொண்டு செல்லுங்கள்'],
    doNot: ['Do NOT induce vomiting if swallowed', 'Do NOT give milk or food', 'Do NOT leave alone'],
    doNotSi: ['ගිලිඳ නම් වමනය ඇති නොකරන්න', 'කිරි හෝ ආහාර නොදෙන්න', 'තනිව නොතබන්න'],
    doNotTa: ['விழுங்கினால் வாந்தி எடுக்காதீர்கள்', 'பால் அல்லது உணவு கொடுக்காதீர்கள்', 'தனியாக விடாதீர்கள்'],
  },
  {
    id: '3',
    title: 'Heat Stroke',
    titleSi: 'තාප ආඝාතය',
    titleTa: 'வெப்ப அடி',
    icon: 'wb_sunny',
    color: '#E65100',
    category: 'environmental',
    symptoms: ['Body temp above 40°C', 'Hot dry skin', 'Confusion or unconsciousness', 'Rapid heartbeat', 'No sweating'],
    symptomsSi: ['ශරීර උෂ්ණය 40°C ඉහළ', 'උණුසුම් වියළි සම', 'ව්‍යාකූලත්වය', 'වේගවත් හෘදස්පන්දනය'],
    symptomsTa: ['உடல் வெப்பம் 40°C மேல்', 'சூடான வறண்ட தோல்', 'குழப்பம்', 'விரைவான இதயத்துடிப்பு'],
    steps: [
      'Move to cool shaded area immediately',
      'Remove excess clothing',
      'Apply cool water to skin, especially neck and armpits',
      'Fan the victim continuously',
      'Give cool water to drink if conscious',
      'Call 1990 immediately',
    ],
    stepsSi: ['සෙවනැලි ස්ථානයකට ගෙනයන්න', 'අතිරේක ඇඳුම් ඉවත් කරන්න', 'සිසිල් ජලය සමට ගෑ', 'වාතය ලබා දෙන්න', 'දැනුම් ඇත්නම් සිසිල් ජලය දෙන්න', '1990 අමතන්න'],
    stepsTa: ['உடனடியாக நிழலுக்கு அழைத்துச் செல்லுங்கள்', 'கூடுதல் ஆடைகள் நீக்கவும்', 'குளிர் நீர் தோலில் தடவுங்கள்', 'விசிறி கொண்டு காற்று கொடுங்கள்', 'நனைந்திருந்தால் குளிர் நீர் கொடுங்கள்', '1990 அழைக்கவும்'],
    doNot: ['Do NOT give alcoholic drinks', 'Do NOT use ice water', 'Do NOT leave in the sun'],
    doNotSi: ['මධ්‍යසාර බීම නොදෙන්න', 'අයිස් ජලය භාවිත නොකරන්න', 'හිරු රශ්මියේ නොතබන්න'],
    doNotTa: ['மது பானங்கள் கொடுக்காதீர்கள்', 'பனி நீர் பயன்படுத்தாதீர்கள்', 'வெயிலில் விடாதீர்கள்'],
  },
  {
    id: '4',
    title: 'Cuts & Wounds',
    titleSi: 'කැපුම් සහ තුවාල',
    titleTa: 'வெட்டுக்கள் மற்றும் காயங்கள்',
    icon: 'healing',
    color: '#C62828',
    category: 'injury',
    symptoms: ['Bleeding', 'Pain at wound site', 'Swelling', 'Possible infection signs'],
    symptomsSi: ['රතිරකාර', 'වේදනාව', 'ඉදිමීම', 'ආසාදන සලකුණු'],
    symptomsTa: ['இரத்தப்போக்கு', 'வலி', 'வீக்கம்', 'தொற்று அறிகுறிகள்'],
    steps: [
      'Apply direct pressure with clean cloth',
      'Elevate the injured area above heart level',
      'Clean wound gently with clean water',
      'Apply antiseptic if available',
      'Cover with sterile bandage',
      'Seek medical attention if deep or won\'t stop bleeding',
    ],
    stepsSi: ['පිරිසිදු රෙද්දකින් පීඩනය ගෙ', 'තුවාල ස්ථානය හෘදයට ඉහළ රක්ෂා', 'ජලයෙන් සෙමෙන් සේදන්න', 'ඇත්නම් ප්‍රතිශීලක ගෑ', 'වෙළුම් පටියෙන් ආවරණය', 'ගැඹුරු නම් රෝහලට'],
    stepsTa: ['சுத்தமான துணியால் நேரடி அழுத்தம் கொடுங்கள்', 'காயத்தை இதயத்திற்கு மேலே உயர்த்துங்கள்', 'சுத்தமான நீரால் மெதுவாக கழுவவும்', 'கிடைத்தால் ஆண்டிசெப்டிக் தடவுங்கள்', 'மலட்டு கட்டுப்போட்டு மூடுங்கள்', 'ஆழமான காயமாக இருந்தால் மருத்துவரிடம் செல்லுங்கள்'],
    doNot: ['Do NOT remove embedded objects', 'Do NOT use dirty cloth', 'Do NOT ignore signs of infection'],
    doNotSi: ['ඇතුළු වූ දේ ඉවත් නොකරන්න', 'අපිරිසිදු රෙදි නොදා', 'ආසාදන සලකුණු නොතකා හරින්න එපා'],
    doNotTa: ['உட்புகுந்த பொருட்களை எடுக்காதீர்கள்', 'அழுக்கு துணி பயன்படுத்தாதீர்கள்', 'தொற்று அறிகுறிகளை புறக்கணிக்காதீர்கள்'],
  },
  {
    id: '5',
    title: 'Eye Injury',
    titleSi: 'ඇස් තුවාල',
    titleTa: 'கண் காயம்',
    icon: 'visibility',
    color: '#1565C0',
    category: 'injury',
    symptoms: ['Pain in eye', 'Redness or swelling', 'Blurred vision', 'Foreign object sensation'],
    symptomsSi: ['ඇසේ වේදනාව', 'රතු ගැනීම', 'දැක්ම බොදු', 'යමක් ඇති බවක් දැනීම'],
    symptomsTa: ['கண்ணில் வலி', 'சிவப்பு அல்லது வீக்கம்', 'மங்கலான பார்வை', 'அந்நிய பொருள் உணர்வு'],
    steps: [
      'Do NOT rub the eye',
      'Flush with clean water for 15 minutes if chemical',
      'Cover eye with clean cloth (do not press)',
      'Seek medical attention immediately',
    ],
    stepsSi: ['ඇස නොඅතිකන්න', 'රසායනික නම් 15 min ජලයෙන් සේදන්න', 'පිරිසිදු රෙද්දෙන් ආවරණය කරන්න', 'වහාම රෝහලට යන්න'],
    stepsTa: ['கண்ணை தேய்க்காதீர்கள்', 'வேதிப்பொருளாக இருந்தால் 15 நிமிடம் நீரால் கழுவவும்', 'சுத்தமான துணியால் மூடுங்கள்', 'உடனடியாக மருத்துவரிடம் செல்லுங்கள்'],
    doNot: ['Do NOT rub the eye', 'Do NOT try to remove embedded objects', 'Do NOT use eye drops without medical advice'],
    doNotSi: ['ඇස නොඅතිකන්න', 'ඇතුළු දේ ඉවත් කිරීමට නොසිතන්න', 'ඖෂධ ඇස් බිඳු නොගන්න'],
    doNotTa: ['கண்ணை தேய்க்காதீர்கள்', 'உட்புகுந்த பொருட்களை நீக்க முயற்சிக்காதீர்கள்', 'மருத்துவ ஆலோசனை இல்லாமல் கண் சொட்டு மருந்து பயன்படுத்தாதீர்கள்'],
  },
  {
    id: '6',
    title: 'Allergic Reaction',
    titleSi: 'අසාත්මිකතා ප්‍රතික්‍රියා',
    titleTa: 'ஒவ்வாமை எதிர்வினை',
    icon: 'coronavirus',
    color: '#AD1457',
    category: 'medical',
    symptoms: ['Skin rash or hives', 'Swollen face or throat', 'Difficulty breathing', 'Rapid pulse'],
    symptomsSi: ['සම රෑප', 'මුහුණ ඉදිමීම', 'හුස්ම ගැනීමේ අපහසුව', 'වේගවත් ස්පන්දනය'],
    symptomsTa: ['தோல் தடிப்பு', 'முகம் அல்லது தொண்டை வீக்கம்', 'சுவாசிக்க சிரமம்', 'விரைவான நாடித்துடிப்பு'],
    steps: [
      'Identify and remove the allergen source',
      'Call 1990 immediately for severe reactions',
      'If available, use epinephrine auto-injector',
      'Lay person flat with legs elevated',
      'Loosen tight clothing',
    ],
    stepsSi: ['අසාත්මිකතාව ඉවත් කරන්න', 'දරුණු නම් 1990 අමතන්න', 'ඇත්නම් ස්වයංක්‍රිය එන්නතක් භාවිත කරන්න', 'කකුල් ඉහළට දමා නිදවන්න', 'තද ඇඳුම් ලිහිල් කරන්න'],
    stepsTa: ['ஒவ்வாமை மூலத்தை அகற்றவும்', 'கடுமையாக இருந்தால் 1990 அழைக்கவும்', 'கிடைத்தால் எபிநெப்ரின் ஊசி பயன்படுத்தவும்', 'கால்களை உயர்த்தி படுக்க வையுங்கள்', 'இறுக்கமான ஆடைகளை தளர்த்துங்கள்'],
    doNot: ['Do NOT give anything by mouth if unconscious', 'Do NOT leave alone'],
    doNotSi: ['දැනුමක් නැත්නම් ආහාර නොදෙන්න', 'තනිව නොතබන්න'],
    doNotTa: ['நனைவிழந்திருந்தால் உணவு கொடுக்காதீர்கள்', 'தனியாக விடாதீர்கள்'],
  },
];

// ── Static safety tips ─────────────────────────────────────────────────
const SAFETY_TIPS = [
  {
    id: '1',
    title: 'Pesticide Safety',
    titleSi: 'පළිබෝධනාශක සුරක්ෂිතතාව',
    titleTa: 'பூச்சிக்கொல்லி பாதுகாப்பு',
    description: 'Always wear gloves, mask and protective clothing. Never eat or drink while handling pesticides.',
    descriptionSi: 'සැමවිටම අත්වැසුම්, මාස්ක් සහ ආරක්ෂිත ඇඳුම් 착용 කරන්න.',
    descriptionTa: 'எப்போதும் கையுறைகள், முகமூடி மற்றும் பாதுகாப்பு ஆடை அணியுங்கள்.',
    icon: 'health_and_safety',
    color: '#2E7D32',
    category: 'chemical',
  },
  {
    id: '2',
    title: 'Sun Protection',
    titleSi: 'හිරු ආරක්ෂාව',
    titleTa: 'சூரிய பாதுகாப்பு',
    description: 'Wear a hat and apply sunscreen. Avoid working in the sun between 10am-3pm.',
    descriptionSi: 'තොප්පිය 着用 කරන්න. ඔලිව් 10 සිට 3 දක්වා හිරු රශ්මියේ වැඩ කිරීමෙන් වළකින්න.',
    descriptionTa: 'தொப்பி அணிந்து சன்ஸ்கிரீன் தடவுங்கள். காலை 10 முதல் மாலை 3 வரை வெயிலில் வேலை செய்வதை தவிர்க்கவும்.',
    icon: 'wb_sunny',
    color: '#E65100',
    category: 'environmental',
  },
  {
    id: '3',
    title: 'Tool Safety',
    titleSi: 'මෙවලම් සුරක්ෂිතතාව',
    titleTa: 'கருவி பாதுகாப்பு',
    description: 'Keep tools sharp and in good condition. Store safely away from children.',
    descriptionSi: 'මෙවලම් තියුණු හා හොඳ තත්ත්වයේ තබාගන්න. ළමයින්ගෙන් ඈතින් ගබඩා කරන්න.',
    descriptionTa: 'கருவிகளை கூர்மையாகவும் நல்ல நிலையிலும் வையுங்கள். குழந்தைகளிடமிருந்து பாதுகாப்பாக சேமித்து வையுங்கள்.',
    icon: 'build',
    color: '#1565C0',
    category: 'tools',
  },
  {
    id: '4',
    title: 'Hydration',
    titleSi: 'ජලය ගැනීම',
    titleTa: 'நீரேற்றம்',
    description: 'Drink at least 2-3 liters of water daily when working in the field.',
    descriptionSi: 'කෙතේ වැඩ කරන විට දිනකට අවම 2-3 ලීටර් ජලය පානය කරන්න.',
    descriptionTa: 'வயலில் வேலை செய்யும்போது தினமும் குறைந்தது 2-3 லிட்டர் தண்ணீர் குடியுங்கள்.',
    icon: 'water_drop',
    color: '#0277BD',
    category: 'health',
  },
  {
    id: '5',
    title: 'Electrical Safety',
    titleSi: 'විද්‍යුත් සුරක්ෂිතතාව',
    titleTa: 'மின் பாதுகாப்பு',
    description: 'Never touch power lines. Keep electrical equipment dry and away from water.',
    descriptionSi: 'විදුලි රැහැන් නොස්පර්ශ කරන්න. විදුලි උපකරණ වලින් ජලය ඈත් කරන්න.',
    descriptionTa: 'மின் கம்பிகளை தொடாதீர்கள். மின் உபகரணங்களை நீரிலிருந்து விலக்கி வையுங்கள்.',
    icon: 'electric_bolt',
    color: '#F9A825',
    category: 'electrical',
  },
  {
    id: '6',
    title: 'Wildlife Awareness',
    titleSi: 'වන සත්ත්ව දැනුවත්භාවය',
    titleTa: 'வனவிலங்கு விழிப்புணர்வு',
    description: 'Be alert for snakes and other wildlife. Wear boots when working in tall grass.',
    descriptionSi: 'සර්පයින් සහ වෙනත් සතුන් ගැන සැලකිලිමත් වන්න. දිගු තණකොළ ලෙල් ශ්‍රමය කරන විට සපත්තු着 කරන්න.',
    descriptionTa: 'பாம்புகள் மற்றும் பிற விலங்குகள் குறித்து விழிப்பாக இருங்கள். உயரமான புல்வெளியில் வேலை செய்யும்போது பூட்ஸ் அணியுங்கள்.',
    icon: 'pest_control',
    color: '#558B2F',
    category: 'wildlife',
  },
];

// ── GET /api/v1/safety/emergency-contacts ─────────────────────────────
exports.getEmergencyContacts = async (req, res) => {
  try {
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: EMERGENCY_CONTACTS,
    });
  } catch (error) {
    logger.error('Get emergency contacts error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch emergency contacts' });
  }
};

// ── GET /api/v1/safety/first-aid ──────────────────────────────────────
exports.getFirstAidGuides = async (req, res) => {
  try {
    const { category } = req.query;
    let guides = FIRST_AID_GUIDES;
    if (category) guides = guides.filter((g) => g.category === category);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: guides,
      count: guides.length,
    });
  } catch (error) {
    logger.error('Get first aid guides error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch first aid guides' });
  }
};

// ── GET /api/v1/safety/first-aid/:id ─────────────────────────────────
exports.getFirstAidGuideById = async (req, res) => {
  try {
    const guide = FIRST_AID_GUIDES.find((g) => g.id === req.params.id);
    if (!guide) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({ success: false, message: 'Guide not found' });
    }
    res.status(HTTP_STATUS.OK).json({ success: true, data: guide });
  } catch (error) {
    logger.error('Get first aid guide error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch guide' });
  }
};

// ── GET /api/v1/safety/tips ───────────────────────────────────────────
exports.getSafetyTips = async (req, res) => {
  try {
    const { category } = req.query;
    let tips = SAFETY_TIPS;
    if (category) tips = tips.filter((t) => t.category === category);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: tips,
      count: tips.length,
    });
  } catch (error) {
    logger.error('Get safety tips error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ success: false, message: 'Failed to fetch safety tips' });
  }
};

// ── GET /api/v1/safety/nearby-hospitals ───────────────────────────────
// Query: lat, lng, radius (meters, default 10000)
exports.getNearbyHospitals = async (req, res) => {
  try {
    const { lat, lng, radius = 10000 } = req.query;

    if (!lat || !lng) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'lat and lng are required',
      });
    }

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: 'Google Maps API key not configured',
      });
    }

    // ── Google Places Nearby Search ─────────────────────────────
    const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=hospital&key=${apiKey}`;

    const placesResponse = await axios.get(placesUrl, { timeout: 10000 });
    const places = placesResponse.data.results || [];

    // ── Get distance matrix for top 10 results ──────────────────
    const topPlaces = places.slice(0, 10);
    const destinations = topPlaces
      .map((p) => `${p.geometry.location.lat},${p.geometry.location.lng}`)
      .join('|');

    let distanceData = {};
    if (topPlaces.length > 0) {
      const distanceUrl = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${lat},${lng}&destinations=${destinations}&mode=driving&key=${apiKey}`;
      const distanceResponse = await axios.get(distanceUrl, { timeout: 10000 });
      distanceData = distanceResponse.data;
    }

    // ── Fetch phone numbers via Place Details for top 5 ─────────
    const hospitalsWithDetails = await Promise.all(
      topPlaces.slice(0, 8).map(async (place, index) => {
        let phone = null;
        try {
          const detailUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${place.place_id}&fields=formatted_phone_number,opening_hours&key=${apiKey}`;
          const detailRes = await axios.get(detailUrl, { timeout: 5000 });
          phone = detailRes.data.result?.formatted_phone_number || null;
        } catch (_) {}

        const distanceElement =
          distanceData?.rows?.[0]?.elements?.[index];
        const distanceText = distanceElement?.distance?.text || null;
        const durationText = distanceElement?.duration?.text || null;
        const distanceValue = distanceElement?.distance?.value || 999999;

        return {
          id: place.place_id,
          name: place.name,
          address: place.vicinity,
          phone,
          lat: place.geometry.location.lat,
          lng: place.geometry.location.lng,
          distance: distanceText,
          duration: durationText,
          distanceValue,
          rating: place.rating || null,
          isOpen: place.opening_hours?.open_now ?? null,
        };
      })
    );

    // Sort by actual distance
    hospitalsWithDetails.sort((a, b) => a.distanceValue - b.distanceValue);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: hospitalsWithDetails,
      count: hospitalsWithDetails.length,
    });
  } catch (error) {
    logger.error('Get nearby hospitals error:', error);
    res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Failed to fetch nearby hospitals',
    });
  }
};
