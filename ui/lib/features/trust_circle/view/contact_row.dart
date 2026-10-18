import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/trust_contact.dart';
import 'labels.dart';

/// One contact in a list: avatar, name, phone and the consent state as icon
/// plus text. The whole row is the tap target (at least 56 dp).
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    required this.onTap,
    this.showDivider = true,
  });

  final TrustContact contact;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    final style = contactStatusStyle(contact.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '${contact.name}, ${style.label}',
          excludeSemantics: true,
          onTap: onTap,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: space.rowHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: space.sm),
                child: Row(
                  children: [
                    InitialsAvatar(name: contact.name),
                    SizedBox(width: space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: context.text.bodyMedium?.copyWith(
                              color: colors.onSurfaceStrong,
                            ),
                          ),
                          Text(
                            contact.phone,
                            style: context.text.bodySmall?.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                          SizedBox(height: space.xs),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: StatusChip(
                              label: style.label,
                              icon: style.icon,
                              tone: style.tone,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: space.iconMd,
                      color: colors.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: space.xxl + space.md),
            child: Divider(color: colors.mist, height: space.hairline),
          ),
      ],
    );
  }
}
