import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final Color color;

  const LoadingWidget({Key? key, this.color = Colors.blue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: color));
  }
}
