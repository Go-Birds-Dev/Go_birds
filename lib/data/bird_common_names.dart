/// Spanish common names keyed by scientific name (VGG16/MobileNet + DenseNet sets).
const Map<String, String> kBirdCommonNames = {
  'Ara ararauna': 'Guacamayo Azuliamarillo',
  'Chroicocephalus ridibundus': 'Gaviota Reidora',
  'Eubucco bourcierii': 'Cabezón Cabecirrojo',
  'Laterallus albigularis': 'Polluela Carrasqueadora',
  'Melanerpes formicivorus': 'Carpintero Bellotero',
  'Patagioenas subvinacea': 'Paloma Vinosa',
  'Platalea ajaja': 'Espátula Rosada',
  'Rynchops niger': 'Rayador Americano',
  'Theristicus caudatus': 'Bandurria Común',
  'Vultur gryphus': 'Cóndor Andino',
  'Anisognathus igniventris': 'Tángara de Vientre Naranja',
  'Arremon auantiirostris': 'Rascador Piquinaranja',
  'Basileuterus rufifrons': 'Reinita de Corona Roja',
  'Columba livia': 'Paloma Doméstica',
  'Grallaria ruficapilla': 'Tororoi Cabecicastaño',
  'Pachyramphus versicolor': 'Anambé Versicolor',
  'Pheucticus ludovicianus': 'Picogrueso Pechirrosado',
  'Pipra mentalis': 'Saltarín Cabeciamarillo',
  'Sturnella magna': 'Turpial Oriental',
  'Thraupis palmarum': 'Tángara de Palmeras',
};

String commonNameForScientific(String scientific) =>
    kBirdCommonNames[scientific] ?? scientific;
