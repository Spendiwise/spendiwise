// lib/controllers/check_goal_milestones.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../utils/app_globals.dart';

Future<void> checkGoalMilestones({
  required double balance,
  required String email,
  String? groupId,
  required int goalFlag,
}) async {
  // 1) Load all goals for this user or group
  final goalsSnapshot = await FirebaseFirestore.instance
      .collection('goals')
      .where(goalFlag == 0 ? 'email' : 'groupId',
      isEqualTo: goalFlag == 0 ? email : groupId)
      .get();

  for (var doc in goalsSnapshot.docs) {
    final data = doc.data();
    final target = (data['target'] as num).toDouble();
    final title = data['title'] as String;
    final goalId = doc.id;

    // 2) Define milestones including 100%
    final milestones = {
      25: target * 0.25,
      50: target * 0.50,
      75: target * 0.75,
      100: target,
    };

    // 3) Sort percents descending so we only fire the highest one
    final sortedPercents = milestones.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // 4) Find the highest milestone not yet sent
    for (final percent in sortedPercents) {
      final triggerAmount = milestones[percent]!;
      if (balance >= triggerAmount) {
        // check if this milestone already exists
        final existing = await FirebaseFirestore.instance
            .collection('notification')
            .where('goalId', isEqualTo: goalId)
            .where('milestone', isEqualTo: percent)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          // write notification doc
          await FirebaseFirestore.instance.collection('notification').add({
            'title': percent == 100
                ? '🎉 Goal achieved: 100%'
                : '🎯 Goal progress: $percent%',
            'description': percent == 100
                ? 'You have fully achieved your goal "$title"! Congratulations!'
                : 'You have reached $percent% of your goal "$title". Keep going!',
            'email': email,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            'goalId': goalId,
            'milestone': percent,
          });

          // show fancy pop-out
          Flushbar(
            title: percent == 100 ? '🎉 Goal Achieved!' : '🎯 Milestone Reached',
            message: percent == 100
                ? 'Congratulations on completing "$title"!'
                : 'You are $percent% of the way to "$title".',
            icon: Icon(Icons.notifications_active, color: Colors.white),
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.green.shade700,
            flushbarPosition: FlushbarPosition.TOP,
            animationDuration: Duration(milliseconds: 500),
          ).show(navigatorKey.currentContext!);

          // only one notification per transaction
          break;
        }
      }
    }
  }
}
