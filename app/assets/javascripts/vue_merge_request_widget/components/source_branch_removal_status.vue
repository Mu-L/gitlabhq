<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    removesBranchText: __('Deletes the source branch'),
    tooltipTitle: __('A user with write access to the source branch selected this option'),
  },
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <p v-once class="mr-info-list gl-mb-0 gl-ml-7 gl-pb-5">
    <span class="status-text">
      {{ $options.i18n.removesBranchText }}
    </span>
    <gl-icon
      v-gl-tooltip.hover
      :title="$options.i18n.tooltipTitle"
      :aria-label="$options.i18n.tooltipTitle"
      name="question-o"
    />
  </p>
</template>
