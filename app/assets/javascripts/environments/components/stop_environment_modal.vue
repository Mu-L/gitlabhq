<script>
import { GlSprintf, GlTooltipDirective, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import eventHub from '../event_hub';
import stopEnvironmentMutation from '../graphql/mutations/stop_environment.mutation.graphql';

export default {
  yamlDocsLink: helpPagePath('ci/yaml/index'),
  stoppingEnvironmentDocsLink: helpPagePath('ci/environments/index', {
    anchor: 'stopping-an-environment',
  }),

  id: 'stop-environment-modal',
  name: 'StopEnvironmentModal',

  components: {
    GlModal,
    GlSprintf,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    environment: {
      type: Object,
      required: true,
    },
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    primaryProps() {
      return {
        text: s__('Environments|Stop environment'),
        attributes: { variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    hasStopAction() {
      return this.graphql ? this.environment.hasStopAction : this.environment.has_stop_action;
    },
  },

  methods: {
    onSubmit() {
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: stopEnvironmentMutation,
          variables: { environment: this.environment },
        });
      } else {
        eventHub.$emit('stopEnvironment', this.environment);
      }
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.id"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="onSubmit"
  >
    <template #modal-title>
      <gl-sprintf :message="s__('Environments|Stopping %{environmentName}')">
        <template #environmentName>
          <span v-gl-tooltip :title="environment.name" class="gl-ml-2 gl-mr-2 gl-grow gl-truncate">
            {{ environment.name }}?
          </span>
        </template>
      </gl-sprintf>
    </template>

    <p>{{ s__('Environments|Are you sure you want to stop this environment?') }}</p>

    <div v-if="!hasStopAction" class="warning_message">
      <p>
        <gl-sprintf
          :message="
            s__(`Environments|Note that this action will stop the environment,
        but it will %{emphasisStart}not%{emphasisEnd} have an effect on any existing deployment
        due to no “stop environment action” being defined
        in the %{ciConfigLinkStart}.gitlab-ci.yml%{ciConfigLinkEnd} file.`)
          "
        >
          <template #emphasis="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #ciConfigLink="{ content }">
            <a :href="$options.yamlDocsLink" target="_blank" rel="noopener noreferrer">
              {{ content }}</a
            >
          </template>
        </gl-sprintf>
      </p>
      <a :href="$options.stoppingEnvironmentDocsLink" target="_blank" rel="noopener noreferrer">{{
        s__('Environments|Learn more about stopping environments')
      }}</a>
    </div>
  </gl-modal>
</template>
