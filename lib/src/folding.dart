enum OrgVisibilityState {
  /// Just the root headline; equivalent to global "overview" state
  folded,

  /// All headlines of all levels
  contents,

  /// All immediate children (subtrees folded)
  children,

  /// Everything
  subtree,
}

extension OrgVisibilityStateJson on OrgVisibilityState? {
  String? toJson() => this?.toString();

  static OrgVisibilityState? fromJson(String? json) => json == null
      ? null
      : OrgVisibilityState.values.singleWhere(
          (value) => value.toString() == json,
        );
}

extension OrgVisibilityStateCycling on OrgVisibilityState {
  OrgVisibilityState get cycleGlobal {
    switch (this) {
      case OrgVisibilityState.folded:
        return OrgVisibilityState.contents;
      case OrgVisibilityState.contents:
        return OrgVisibilityState.subtree;
      case OrgVisibilityState.subtree:
      case OrgVisibilityState.children:
        return OrgVisibilityState.folded;
    }
  }

  OrgVisibilityState cycleSubtree(bool empty) {
    switch (this) {
      case OrgVisibilityState.folded:
        return OrgVisibilityState.children;
      case OrgVisibilityState.contents:
        return empty ? OrgVisibilityState.subtree : OrgVisibilityState.folded;
      case OrgVisibilityState.children:
        return empty ? OrgVisibilityState.folded : OrgVisibilityState.subtree;
      case OrgVisibilityState.subtree:
        return OrgVisibilityState.folded;
    }
  }

  OrgVisibilityState get subtreeState {
    switch (this) {
      case OrgVisibilityState.folded: // fallthrough
      case OrgVisibilityState.contents: // fallthrough
      case OrgVisibilityState.children:
        return OrgVisibilityState.folded;
      case OrgVisibilityState.subtree:
        return OrgVisibilityState.subtree;
    }
  }
}
