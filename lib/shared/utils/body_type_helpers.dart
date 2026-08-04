const List<String> bodyTypeNames = ['none', 'json', 'form', 'raw'];

int bodyTypeStringToIndex(String? bodyType) {
  switch (bodyType) {
    case 'json': return 1;
    case 'form': return 2;
    case 'raw': return 3;
    default: return 0;
  }
}

String? bodyTypeIndexToString(int index) {
  if (index > 0 && index < bodyTypeNames.length) {
    return bodyTypeNames[index];
  }
  return null;
}
