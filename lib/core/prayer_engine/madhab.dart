enum Madhab {
  shafi,
  hanafi,
}

int shadowLength(Madhab madhab) {
  switch (madhab) {
    case Madhab.shafi:
      return 1;
    case Madhab.hanafi:
      return 2;
  }
}
