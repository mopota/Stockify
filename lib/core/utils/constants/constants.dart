
import 'package:stockify/core/di/injections.dart';
import 'package:stockify/core/utils/constants/translations.dart';

import '../../../features/cubit/cubit.dart';

TranslationModel appTranslation() =>
    sl<AppCubit>().translationModel ?? TranslationModel.fromJson({});