class PrefKey {
  static get campus => 'campus';
  static get department => 'department';
  static get year => 'year';
  static get group => 'group';

  static get numberWeeks => 'number_weeks';

  static get primaryColor => 'primary_color';
  static get accentColor => 'accent_color';
  static get noteColor => 'note_color';
  static get isDarkTheme => 'isDark';

  static get isFirstBoot => "is_first_boot";
  static get isLogged => "is_logged";
  static get isHorizontalView => "is_horizontal_view";

  static get cachedIcal => "cached_ical";
  static get ressources => "ressources";

  static get notes => "notes";
  static get customEvent => "custom_event";

  static const defaultNumberWeeks = 4;
  static const defaultPrimaryColor = 0xFFF44336; // = Colors.red[500]
  static const defaultAccentColor = 0xFFFF5252;
  static const defaultNoteColor = 0xFFFFFF00;
  static const defaultDarkTheme = false;
  static const defaultHorizontalView = false;
}
