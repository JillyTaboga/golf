enum Clubs {
  wood,
  iron,
  driver,
  wedge,
  putter;

  int get min => switch (this) {
        Clubs.wood => 2,
        Clubs.iron => 5,
        Clubs.driver => 3,
        Clubs.wedge => 3,
        Clubs.putter => 1,
      };
  int get max => switch (this) {
        Clubs.wood => 6,
        Clubs.iron => 9,
        Clubs.driver => 12,
        Clubs.wedge => 8,
        Clubs.putter => 3,
      };
  int get accuracy => switch (this) {
        Clubs.wood => 85,
        Clubs.iron => 90,
        Clubs.driver => 60,
        Clubs.wedge => 70,
        Clubs.putter => 95,
      };
  String get label => switch (this) {
        Clubs.wood => 'Madeira',
        Clubs.iron => 'Ferro',
        Clubs.driver => 'Driver',
        Clubs.wedge => 'Wedge',
        Clubs.putter => 'Putter',
      };
}
