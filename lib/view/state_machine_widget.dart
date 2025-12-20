import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statemachine/contract/async_side_effect.dart';

import '../contract/async_side_effect_handler.dart';
import '../contract/event.dart';
import '../contract/screen.dart';
import '../contract/state.dart';
import '../contract/ui_side_effect.dart';
import '../core/state_machine.dart';

abstract class StateMachineWidget<
    E extends Event,
    S extends BaseState,
    ASF extends AsyncSideEffect,
    USF extends UISideEffect> extends StatefulWidget {
  const StateMachineWidget({super.key});

  @override
  State<StateMachineWidget<E, S, ASF, USF>> createState() =>
      _StateMachineWidgetState<E, S, ASF, USF>();

  StateMachine<E, S, ASF, USF> injectStateMachine();

  void handleUISideEffect(
      BuildContext context, USF sideEffect, DispatchEvent<E> dispatchEvent);

  void init(S state, DispatchEvent<E> dispatchEvent) {}

  Widget buildLayout(S state, DispatchEvent<E> dispatchEvent);

  void pushReplacement(BuildContext context, Screen screen) {
    context.pushReplacement(screen.path, extra: screen.params);
  }

  void push(BuildContext context, Screen screen, {Object? extra}) {
    context.push(screen.path, extra: extra);
  }

  Future<dynamic> pushForResult(BuildContext context, Screen screen,
      {Object? extra}) {
    return context.push(screen.path, extra: extra);
  }

  void pushNamed(BuildContext context, Screen screen) {
    context.pushNamed(screen.path);
  }

  void pop(BuildContext context) {
    context.pop();
  }

  void go(BuildContext context, Screen screen) {
    context.go(screen.path);
  }

  Widget? getBottomNavigationBar(S state, DispatchEvent<E> dispatchEvent) {
    return null;
  }

  AppBar? getAppBar(S state, DispatchEvent<E> dispatchEvent) {
    return null;
  }

  Widget? getFloatingActionButton(S state, DispatchEvent<E> dispatchEvent) {
    return null;
  }

  bool enableScaffold() {
    return true;
  }

  bool enableLifecycleEvents() {
    return false;
  }

  Color? getScaffoldBackgroundColor() {
    return null;
  }

  void didChangeAppLifecycleState(
      AppLifecycleState state, DispatchEvent<E> dispatchEvent) {}
}

class _StateMachineWidgetState<E extends Event, S extends BaseState,
        ASF extends AsyncSideEffect, USF extends UISideEffect>
    extends State<StateMachineWidget<E, S, ASF, USF>>
    with WidgetsBindingObserver {
  late StateMachine<E, S, ASF, USF> stateMachine;

  late S state;

  @override
  void initState() {
    stateMachine = widget.injectStateMachine();
    state = stateMachine.getState();
    widget.init(state, (event) => stateMachine.dispatchEvent(event));
    stateMachine.getStateStream().stream.listen((event) {
      setState(() {
        state = event;
      });
    });

    stateMachine.getUISideEffect().stream.listen((USF usf) {
      widget.handleUISideEffect(
          context, usf, ((event) => stateMachine.dispatchEvent(event)));
    });

    if (widget.enableLifecycleEvents()) {
      WidgetsBinding.instance.addObserver(this);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    state.screenWidth = MediaQuery.of(context).size.width;
    state.screenHeight = MediaQuery.of(context).size.height;
    GoRouterState routerState = GoRouterState.of(context);
    state.location = routerState.uri.toString();
    state.extra = routerState.extra;

    if (widget.enableScaffold()) {
      return getScaffoldView();
    } else {
      return getMaterialView();
    }
  }

  Widget getScaffoldView() {
    return Scaffold(
      backgroundColor: widget.getScaffoldBackgroundColor(),
      appBar: widget.getAppBar(state, (event) {
        stateMachine.dispatchEvent(event);
      }),
      body: widget.buildLayout(state, (event) {
        stateMachine.dispatchEvent(event);
      }),
      bottomNavigationBar: widget.getBottomNavigationBar(state, (event) {
        stateMachine.dispatchEvent(event);
      }),
      floatingActionButton: widget.getFloatingActionButton(state, (event) {
        stateMachine.dispatchEvent(event);
      }),
    );
  }

  Widget getMaterialView() {
    return Material(
      // color: const Color.fromARGB(0, 36, 3, 26),
      child: widget.buildLayout(state, (event) {
        stateMachine.dispatchEvent(event);
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.didChangeAppLifecycleState(
      state,
      (event) {
        stateMachine.dispatchEvent(event);
      },
    );
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    stateMachine.dispose();
    if (widget.enableLifecycleEvents()) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
