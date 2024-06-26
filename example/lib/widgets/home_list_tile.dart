// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeListTile extends StatelessWidget {
  final String title;
  final String route;
  const HomeListTile({
    Key? key,
    required this.title,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: CupertinoListTile(
        title: Text(title),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        trailing: const Icon(CupertinoIcons.chevron_forward),
      ),
    );
  }
}
