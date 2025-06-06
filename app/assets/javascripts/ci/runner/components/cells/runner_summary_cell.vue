<script>
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { formatNumber } from '~/locale';

import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RunnerCreatedAt from '../runner_created_at.vue';
import RunnerJobCount from '../runner_job_count.vue';
import RunnerName from '../runner_name.vue';
import RunnerTags from '../runner_tags.vue';
import RunnerTypeBadge from '../runner_type_badge.vue';
import RunnerManagersBadge from '../runner_managers_badge.vue';
import {
  I18N_LOCKED_RUNNER_DESCRIPTION,
  I18N_VERSION_LABEL,
  I18N_LAST_CONTACT_LABEL,
} from '../../constants';
import RunnerSummaryField from './runner_summary_field.vue';

export default {
  components: {
    GlIcon,
    GlSprintf,
    TimeAgo,
    RunnerSummaryField,
    RunnerCreatedAt,
    RunnerJobCount,
    RunnerName,
    RunnerTags,
    RunnerTypeBadge,
    RunnerManagersBadge,
    RunnerUpgradeStatusIcon: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_icon.vue'),
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    managersCount() {
      return this.runner.managers?.count || 0;
    },
    firstIpAddress() {
      return this.runner.managers?.nodes?.[0]?.ipAddress || null;
    },
    firstVersion() {
      return this.runner.managers?.nodes?.[0]?.version || null;
    },
    additionalIpAddressCount() {
      return this.managersCount - 1;
    },
  },
  methods: {
    formatNumber,
  },
  i18n: {
    I18N_LOCKED_RUNNER_DESCRIPTION,
    I18N_VERSION_LABEL,
    I18N_LAST_CONTACT_LABEL,
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-3">
    <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
      <slot :runner="runner" name="runner-name">
        <runner-name :runner="runner" />
      </slot>

      <runner-managers-badge :count="managersCount" />
      <gl-icon
        v-if="runner.locked"
        v-gl-tooltip
        :title="$options.i18n.I18N_LOCKED_RUNNER_DESCRIPTION"
        name="lock"
      />
      <runner-type-badge :type="runner.runnerType" />
    </div>
    <div
      v-if="runner.version || runner.description"
      class="gl-mb-2 gl-inline-flex gl-text-subtle md:gl-mb-0"
    >
      <template v-if="firstVersion">
        <div class="gl-shrink-0">
          <runner-upgrade-status-icon :upgrade-status="runner.upgradeStatus" />
          <gl-sprintf :message="$options.i18n.I18N_VERSION_LABEL">
            <template #version>{{ firstVersion }}</template>
          </gl-sprintf>
        </div>
        <div v-if="runner.description" class="gl-mx-2 gl-text-subtle" aria-hidden="true">·</div>
      </template>
      <tooltip-on-truncate
        v-if="runner.description"
        class="gl-block gl-truncate gl-text-left"
        :class="{ 'gl-text-subtle': !runner.description }"
        :title="runner.description"
      >
        {{ runner.description }}
      </tooltip-on-truncate>
    </div>

    <div class="gl-flex gl-flex-wrap gl-gap-x-4 gl-gap-y-2 gl-text-sm">
      <runner-summary-field icon="pipeline" data-testid="job-count" :tooltip="__('Jobs')">
        <runner-job-count :runner="runner" />
      </runner-summary-field>

      <runner-summary-field icon="clock" icon-size="sm">
        <gl-sprintf :message="$options.i18n.I18N_LAST_CONTACT_LABEL">
          <template #timeAgo>
            <time-ago v-if="runner.contactedAt" :time="runner.contactedAt" />
            <template v-else>{{ __('Never') }}</template>
          </template>
        </gl-sprintf>
      </runner-summary-field>

      <runner-summary-field v-if="firstIpAddress" icon="disk" :tooltip="__('IP Address')">
        {{ firstIpAddress }}
        <template v-if="additionalIpAddressCount"
          >(+{{ formatNumber(additionalIpAddressCount) }})</template
        >
      </runner-summary-field>

      <runner-summary-field icon="calendar">
        <runner-created-at :runner="runner" />
      </runner-summary-field>
    </div>

    <runner-tags class="gl-flex gl-flex-wrap gl-gap-2" :tag-list="runner.tagList" :limit="20" />
  </div>
</template>
