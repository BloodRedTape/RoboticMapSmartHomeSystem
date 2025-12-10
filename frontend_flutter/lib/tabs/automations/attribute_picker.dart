import 'package:dart_common/common/attributes.dart';
import 'package:dart_common/dart_common.dart';
import 'package:flutter/material.dart';
import 'package:frontend_flutter/bloc.dart';
import 'package:frontend_flutter/cubits/devices_cubit.dart';

class AttributePicker extends AnyCubitProviderWidget<String?> {
  final String text;
  final bool Function(Attribute) filter;
  final void Function(String?)? onChanged;

  AttributePicker({required this.text, required this.filter, this.onChanged}) : super((p0) => Cubit2(null));

  @override
  Widget buildFromState(BuildContext context, String? guid) {
    final deviceCubit = context.read<DevicesCubit>();

    final attributes = deviceCubit.attributes().where(filter);

    return DropdownButton<String>(
      value: guid,
      hint: Text(text),
      isExpanded: true,
      items:
          attributes.map((attr) {
            return DropdownMenuItem<String>(value: attr.guid, child: Text(deviceCubit.attributeName(attr)));
          }).toList(),
      onChanged: (value) {
        emit(value);
        onChanged?.call(value);
      },
    );
  }
}

class CommandTargetAttributePicker extends AttributePicker {
  CommandTargetAttributePicker({required super.text, Command? command, bool Function(Attribute)? filter, super.onChanged})
      : super(filter: filter ?? (command != null ? command.isSupportedByAttribute : (attr) => true));
}
