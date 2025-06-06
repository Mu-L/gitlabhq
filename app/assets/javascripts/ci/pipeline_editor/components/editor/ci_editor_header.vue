<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  EDITOR_APP_DRAWER_HELP,
  EDITOR_APP_DRAWER_JOB_ASSISTANT,
  EDITOR_APP_DRAWER_NONE,
  pipelineEditorTrackingOptions,
} from '../../constants';

export default {
  i18n: {
    browseCatalog: __('CI/CD Catalog'),
    help: __('Help'),
    jobAssistant: s__('JobAssistant|Job assistant'),
    editorA11y: s__('PipelineEditor|Editor accessibility guide'),
  },
  components: {
    GlButton,
    GlLink,
  },
  mixins: [glFeatureFlagMixin(), Tracking.mixin()],
  inject: ['ciCatalogPath'],
  props: {
    showHelpDrawer: {
      type: Boolean,
      required: true,
    },
    showJobAssistantDrawer: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    editorA11yHelpPagePath() {
      return helpPagePath('ci/pipeline_editor/_index.md', {
        anchor: 'editor-accessibility-options',
      });
    },
  },
  methods: {
    toggleHelpDrawer() {
      if (this.showHelpDrawer) {
        this.$emit('switch-drawer', EDITOR_APP_DRAWER_NONE);
      } else {
        this.$emit('switch-drawer', EDITOR_APP_DRAWER_HELP);
        this.trackHelpDrawerClick();
      }
    },
    toggleJobAssistantDrawer() {
      this.$emit(
        'switch-drawer',
        this.showJobAssistantDrawer ? EDITOR_APP_DRAWER_NONE : EDITOR_APP_DRAWER_JOB_ASSISTANT,
      );
    },
    trackCatalogBrowsing() {
      const { label, actions } = pipelineEditorTrackingOptions;

      this.track(actions.browseCatalog, { label });
    },
    trackHelpDrawerClick() {
      const { label, actions } = pipelineEditorTrackingOptions;
      this.track(actions.openHelpDrawer, { label });
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-flex-col gl-gap-3 gl-border-1 gl-border-solid gl-border-default gl-p-3 md:gl-flex-row md:gl-items-center"
  >
    <slot></slot>
    <gl-button
      :href="ciCatalogPath"
      size="small"
      icon="catalog-checkmark"
      target="_blank"
      data-testid="catalog-repo-link"
      @click="trackCatalogBrowsing"
    >
      {{ $options.i18n.browseCatalog }}
    </gl-button>
    <gl-button
      icon="information-o"
      size="small"
      data-testid="drawer-toggle"
      @click="toggleHelpDrawer"
    >
      {{ $options.i18n.help }}
    </gl-button>
    <gl-button
      v-if="glFeatures.ciJobAssistantDrawer"
      icon="bulb"
      size="small"
      @click="toggleJobAssistantDrawer"
    >
      {{ $options.i18n.jobAssistant }}
    </gl-button>
    <gl-link
      class="gl-p-2 gl-text-center"
      :href="editorA11yHelpPagePath"
      data-testid="editor-accessibility-link"
    >
      {{ $options.i18n.editorA11y }}
    </gl-link>
  </div>
</template>
