import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
export 'package:flutter_bloc/flutter_bloc.dart';

class Cubit2<StateType> extends Cubit<StateType> {
  Cubit2(super.initial);
}

abstract class CubitRefWidget<CubitType extends Cubit<StateType>, StateType> extends StatelessWidget {
  final CubitType cubit;

  const CubitRefWidget(this.cubit, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: cubit, child: BlocBuilder<CubitType, StateType>(builder: (context, state) => buildFromState(context, state)));
  }

  Widget buildFromState(BuildContext context, StateType state);

  void emit(StateType state) {
    cubit.emit(state);
  }
}

abstract class CubitWatchWidget<CubitType extends Cubit<StateType>, StateType> extends StatelessWidget {
  CubitType? _ref = null;

  CubitWatchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CubitType>();
    _ref = cubit;
    return buildFromState(context, cubit.state);
  }

  Widget buildFromState(BuildContext context, StateType state);

  void emit(StateType state) {
    if (_ref == null) throw Exception('CubitProviderWidget, cubit is somehow null');
    _ref?.emit(state);
  }
}

// ignore: must_be_immutable
abstract class CubitProviderWidget<CubitType extends Cubit<StateType>, StateType> extends StatelessWidget {
  final CubitType Function(BuildContext) cubit;

  CubitType? _ref = null;

  CubitProviderWidget(this.cubit, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: cubit,
      child: BlocBuilder<CubitType, StateType>(
        builder: (context, state) {
          _ref = context.read<CubitType>();
          return buildFromState(context, state);
        },
      ),
    );
  }

  Widget buildFromState(BuildContext context, StateType state);

  void emit(StateType state) {
    if (_ref == null) throw Exception('CubitProviderWidget, cubit is somehow null');
    _ref?.emit(state);
  }

  StateType state() {
    return _ref!.state;
  }
}

abstract class AnyCubitRefWidget<StateType> extends CubitRefWidget<Cubit<StateType>, StateType> {
  const AnyCubitRefWidget(super.cubit, {super.key});
}

// ignore: must_be_immutable
abstract class AnyCubitProviderWidget<StateType> extends CubitProviderWidget<Cubit<StateType>, StateType> {
  AnyCubitProviderWidget(super.cubit, {super.key});
}

abstract class FutureWidget<T> extends StatelessWidget {
  final Future<T> future;

  const FutureWidget(this.future, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return buildFromValue(context, snapshot.data!);
        } else if (snapshot.hasError && snapshot.error != null) {
          return buildFromError(context, snapshot.error!);
        } else {
          return buildFromWaiting(context);
        }
      },
    );
  }

  Widget buildFromValue(BuildContext context, T value);

  Widget buildFromWaiting(BuildContext context) {
    return Text('Loading...');
  }

  Widget buildFromError(BuildContext context, Object error) {
    return Text(error.toString());
  }
}

class FastFutureWidget<T> extends FutureWidget<T> {
  final Widget Function(BuildContext context, T value) builder;

  const FastFutureWidget(super.future, this.builder, {super.key});

  @override
  Widget buildFromValue(BuildContext context, T value) {
    return builder(context, value);
  }
}

class Stretched extends StatelessWidget {
  final Widget child;

  const Stretched({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, child: child);
  }
}

class DecoratedText extends StatelessWidget {
  final String text;
  final IconData? heading;
  final TextStyle? style;

  const DecoratedText({super.key, required this.text, this.heading, this.style});

  @override
  Widget build(BuildContext context) {
    if (heading == null) return Text(text, style: style);

    return Row(children: [Icon(heading, color: style?.color), Text(text, style: style)]);
  }
}

class Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const Info({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24), const SizedBox(height: 8), Text(text)]));
  }
}
