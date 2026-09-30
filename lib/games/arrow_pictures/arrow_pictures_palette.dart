/// The colours a picture is revealed in once its last arrow has left.
///
/// A picture mask uses these letters where the plain masks use `#`; `.` is
/// still outside the picture, and any non-`.` cell holds an arrow, so colouring
/// a picture can never change its board.
///
/// Colour appears only on the finished picture, never during play: this
/// audience reads colour as a rule ("do the red ones go first?"), and the arrows
/// already carry every bit of game information by direction alone. A small
/// fixed palette keeps the pictures looking like one set, and every colour is
/// dark or saturated enough to stand out against the light board (#E8EDF2) —
/// hence cream rather than white.
///
/// ARGB, so this file stays free of Flutter imports like the rest of the models.
const picturePalette = <String, int>{
  '#': 0xFF8D6E63, // unassigned — the game's brown; a finished set has none
  'k': 0xFF37474F, // charcoal: outlines, eyes, iron, tyres
  's': 0xFF9AA5AE, // stone grey: rock, steel, pigeon-grey
  'w': 0xFFF3E9D2, // cream: white fur, feathers, sails, snow, paper
  't': 0xFFD2B48C, // tan: sand, straw, light wood, biscuit
  'n': 0xFF8D6E63, // brown: wood, fur, bark
  'N': 0xFF5D4037, // dark brown: trunks, dark wood, chocolate
  'r': 0xFFD0504A, // red
  'c': 0xFFE8A0B0, // pink
  'o': 0xFFEF8A3D, // orange
  'y': 0xFFF2C94C, // yellow, gold
  'g': 0xFF7CB35B, // green: leaves, grass
  'G': 0xFF2E7D4F, // dark green: fir, deep foliage
  'b': 0xFF5B9BD5, // blue: sky, water
  'B': 0xFF2F4F7F, // navy: deep water, night, uniforms
  'p': 0xFF8E6BB8, // purple
};
