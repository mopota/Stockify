
import 'package:stockify/core/utils/constants/translations.dart';

import '../../../features/cubit/cubit.dart';

TranslationModel appTranslation() =>
AppCubit().translationModel ?? TranslationModel.fromJson({});