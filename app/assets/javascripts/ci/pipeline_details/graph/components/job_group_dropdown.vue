<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import { FAILED_STATUS } from '~/ci/constants';
import { JOB_DROPDOWN } from '../constants';
import JobItem from './job_item.vue';

/**
 * Renders the dropdown for the pipeline graph.
 *
 * The object provided as `group` corresponds to app/serializers/job_group_entity.rb.
 *
 */
export default {
  components: {
    JobDropdownItem,
    JobItem,
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: false,
      default: -1,
    },
    cssClassJobName: {
      type: [String, Array],
      required: false,
      default: '',
    },
    stageName: {
      type: String,
      required: false,
      default: '',
    },
  },
  jobItemTypes: {
    jobDropdown: JOB_DROPDOWN,
  },
  data() {
    return {
      isMobile: false,
      showTooltip: false,
    };
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.group.name}-${this.pipelineId}` : '';
    },
    dropdownTooltip() {
      return !this.showTooltip ? this.group?.status?.tooltip || this.group?.status?.text : '';
    },
    placement() {
      // MR !49053:
      // We change the placement of the dropdown based on the breakpoint.
      // This is not an ideal solution, but rather a temporary solution
      // until we find a better solution in
      // https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues/2400
      return this.isMobile ? 'bottom-start' : 'right-start';
    },
    isFailed() {
      return this.group?.status?.group === 'failed';
    },
    nonFailedJobs() {
      return this.group?.jobs.filter((job) => job.status?.group !== FAILED_STATUS);
    },
    failedJobs() {
      return this.group?.jobs.filter((job) => job.status?.group === FAILED_STATUS);
    },
    hasFailedJobs() {
      return this.failedJobs.length > 0;
    },
  },
  methods: {
    handleResize() {
      this.isMobile = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
    showDropdown() {
      this.showTooltip = true;
    },
    hideDropdown() {
      this.showTooltip = false;
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :id="computedJobId"
    v-gl-resize-observer="handleResize"
    v-gl-tooltip.viewport.left="{ customClass: 'ci-job-component-tooltip' }"
    :title="dropdownTooltip"
    block
    fluid-width
    :placement="placement"
    data-testid="job-dropdown-container"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template #toggle>
      <button
        type="button"
        :class="[cssClassJobName, { 'ci-job-item-failed': isFailed }]"
        class="gl-bg-transparent"
      >
        <div class="gl-flex gl-items-center gl-justify-between">
          <job-item
            :type="$options.jobItemTypes.jobDropdown"
            :job="group"
            :stage-name="stageName"
            hide-tooltip
          />
          <gl-badge variant="muted">
            {{ group.size }}
          </gl-badge>
        </div>
      </button>
    </template>
    <ul class="gl-m-0 gl-w-34 gl-overflow-y-auto gl-p-0" @click.stop>
      <gl-disclosure-dropdown-group v-if="hasFailedJobs" data-testid="failed-jobs">
        <template #group-label>
          {{ s__('Pipelines|Failed jobs') }}
        </template>
        <job-dropdown-item
          v-for="job in failedJobs"
          :key="job.id"
          :job="job"
          @jobActionExecuted="$emit('pipelineActionRequestComplete')"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group :bordered="hasFailedJobs">
        <job-dropdown-item
          v-for="job in nonFailedJobs"
          :key="job.id"
          :job="job"
          @jobActionExecuted="$emit('pipelineActionRequestComplete')"
        />
      </gl-disclosure-dropdown-group>
    </ul>
  </gl-disclosure-dropdown>
</template>
