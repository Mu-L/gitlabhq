<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';

export default {
  components: {
    GlAvatar,
    GlIcon,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    imgSize: {
      type: Number,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
  },
  computed: {
    avatarUrl() {
      return (
        this.user.avatarUrl || this.user.avatar || this.user.avatar_url || gon.default_avatar_url
      );
    },
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    hasMergeIcon() {
      const canMerge = this.user.mergeRequestInteraction?.canMerge || this.user.can_merge;
      return this.isMergeRequest && !canMerge;
    },
  },
};
</script>

<template>
  <span class="gl-relative">
    <gl-avatar
      :label="user.name"
      :src="avatarUrl"
      :size="imgSize"
      aria-hidden="true"
      data-testid="avatar-image"
    />
    <gl-icon
      v-if="hasMergeIcon"
      :aria-label="__('Cannot merge')"
      name="warning-solid"
      class="merge-icon"
    />
  </span>
</template>
