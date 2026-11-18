class AppStrings {
  // App
  static const String appTitle = 'TurnirPro';
  static const String tournamentManager = 'Futbol Turniri Boshqaruvchisi';

  // Navigation
  static const String navHome = 'Bosh sahifa';
  static const String navSchedule = 'Taqvim';
  static const String navStandings = 'Jadval';
  static const String navTeams = 'Jamoalar';
  static const String navStatistics = 'Statistika';
  static const String navSettings = 'Sozlamalar';

  // Common actions
  static const String save = 'Saqlash';
  static const String cancel = 'Bekor qilish';
  static const String delete = 'O‘chirish';
  static const String edit = 'Tahrirlash';
  static const String add = 'Qo‘shish';
  static const String close = 'Yopish';
  static const String confirm = 'Tasdiqlash';
  static const String retry = 'Qayta urinish';
  static const String search = 'Qidirish';
  static const String refresh = 'Yangilash';
  static const String export = 'Eksport';
  static const String share = 'Ulashish';
  static const String archive = 'Arxivlash';
  static const String unarchive = 'Arxivdan chiqarish';
  static const String reset = 'Qayta boshlash';

  // Teams
  static const String teamsTitle = 'Jamoalar ro‘yxati';
  static const String addTeam = 'Yangi jamoa';
  static const String editTeam = 'Jamoani tahrirlash';
  static const String deleteTeam = 'Jamoani o‘chirish';
  static const String teamName = 'Jamoa nomi';
  static const String teamColor = 'Jamoa rangi';
  static const String selectColor = 'Rangni tanlang';
  static const String activeTeams = 'Faol jamoalar';
  static const String archivedTeams = 'Arxivlangan jamoalar';
  static const String noTeamsFound = 'Jamoalar mavjud emas';
  static const String teamAddedSuccess = 'Jamoa muvaffaqiyatli qo‘shildi';
  static const String teamUpdatedSuccess = 'Jamoa ma’lumotlari yangilandi';
  static const String teamDeletedSuccess = 'Jamoa o‘chirildi';
  static const String teamArchivedSuccess = 'Jamoa arxivlandi';
  static const String teamUnarchivedSuccess = 'Jamoa arxivdan chiqarildi';
  static const String teamNameValidation =
      'Iltimos, jamoa nomini kiriting (kamida 2 belgi)';
  static const String teamMatchesWarning =
      'Bu jamoa o‘yinlarda qatnashgan. Eski natijalar saqlanishi uchun uni butunlay o‘chirish o‘rniga arxivlash tavsiya etiladi.';
  static const String confirmDeleteTeam =
      'Haqiqatan ham bu jamoani o‘chirmoqchimisiz?';
  static const String confirmArchiveTeam = 'Jamoani arxivlamoqchimisiz?';

  // Schedule & Matches
  static const String scheduleTitle = 'O‘yinlar taqvimi';
  static const String round = 'Tur';
  static const String roundLabel = '{0}-tur';
  static const String generateSchedule = 'Taqvimni yaratish';
  static const String generateNextRound = 'Keyingi turni yaratish';
  static const String randomizeUpcoming = 'Qayta taqsimlash';
  static const String editMatchTime = 'Vaqtni o‘zgartirish';
  static const String deleteMatch = 'O‘yinni o‘chirish';
  static const String deleteRound = 'Turni o‘chirish';
  static const String deleteCurrentRound = 'Ushbu turni o‘chirish';
  static const String confirmDeleteRound =
      'Haqiqatan ham ushbu turni va uning barcha o‘yinlarini o‘chirmoqchimisiz?';
  static const String deleteRoundWarning =
      'Diqqat: Ushbu turda natijasi kiritilgan o‘yinlar bor. O‘chirilsa, turnir jadvali ham qayta hisoblanadi.';
  static const String restingTeam = 'Dam oluvchi jamoa';
  static const String enterScore = 'Hisobni kiritish';
  static const String editScore = 'Hisobni tahrirlash';
  static const String resetScore = 'Hisobni bekor qilish';
  static const String saveResult = 'Natijani saqlash';
  static const String matchStatus = 'O‘yin holati';
  static const String statusUpcoming = 'Kutilayotgan';
  static const String statusLive = 'Jonli';
  static const String statusFinished = 'Tugallangan';
  static const String timeSlot = 'O‘yin vaqti';
  static const String selectTimeSlot = 'Vaqt oralig‘ini tanlang';
  static const String vs = 'VS';
  static const String scoreValidation =
      'Hisob manfiy bo‘lmasligi va faqat raqam bo‘lishi kerak';
  static const String confirmDeleteMatch =
      'Haqiqatan ham ushbu o‘yinni o‘chirmoqchimisiz?';
  static const String confirmResetTournament =
      'Turnirni qayta boshlash barcha o‘yin va natijalarni o‘chiradi. Davom etasizmi?';

  // Standings
  static const String standingsTitle = 'Turnir jadvali';
  static const String pos = 'Pos';
  static const String team = 'Jamoa';
  static const String played = 'P';
  static const String won = 'W';
  static const String drawn = 'D';
  static const String lost = 'L';
  static const String goalsFor = 'GF';
  static const String goalsAgainst = 'GA';
  static const String goalDifference = 'GD';
  static const String points = 'Pts';
  static const String exportPdf = 'PDF yuklash';
  static const String exportImage = 'Rasm sifatida saqlash';
  static const String shareTable = 'Jadvalni ulashish';

  // Home
  static const String homeTitle = 'Bosh sahifa';
  static const String totalTeams = 'Jami jamoalar';
  static const String totalMatches = 'Jami o‘yinlar';
  static const String finishedMatches = 'Tugallangan o‘yinlar';
  static const String nextMatch = 'Keyingi o‘yin';
  static const String nextRound = 'Keyingi tur';
  static const String topTeams = 'Yetakchi TOP 3 jamoa';
  static const String recentResults = 'Oxirgi o‘yin natijalari';
  static const String noUpcomingMatches = 'Kutilayotgan o‘yinlar yo‘q';
  static const String noRecentResults = 'Hali tugallangan o‘yinlar yo‘q';

  // Statistics
  static const String statisticsTitle = 'Statistika';
  static const String mostGoalsScored = 'Eng ko‘p gol urgan';
  static const String leastGoalsConceded = 'Eng kam gol o‘tkazgan';
  static const String mostWins = 'Eng ko‘p g‘alaba';
  static const String mostLosses = 'Eng ko‘p mag‘lubiyat';
  static const String bestGoalDiff = 'Eng yaxshi to‘plar farqi';
  static const String mostPoints = 'Eng ko‘p ochko';
  static const String goalsPerMatch = 'O‘rtacha gol';
  static const String totalGoals = 'Jami urilgan gollar';

  // Settings
  static const String settingsTitle = 'Sozlamalar';
  static const String appearance = 'Tashqi ko‘rinish';
  static const String darkMode = 'Qorong‘i rejim';
  static const String lightMode = 'Yorug‘ rejim';
  static const String tournamentSettings = 'Turnirni boshqarish';
  static const String currentTournament = 'Joriy turnir';
  static const String archiveTournament = 'Turnirni arxivlash';
  static const String resetTournament = 'Turnirni qayta boshlash';
  static const String aboutApp = 'Ilova haqida';
}
