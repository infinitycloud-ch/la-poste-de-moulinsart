<template>
  <div class="agent-avatar" :class="{ [size]: true }">
    <img
      v-if="hasAvatar"
      :src="avatarSrc"
      :alt="agent"
      class="avatar-image"
      @error="fallbackToEmoji"
    />
    <span v-else class="avatar-emoji">{{ agentEmoji }}</span>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  agent: {
    type: String,
    required: true
  },
  size: {
    type: String,
    default: 'medium' // small, medium, large
  }
})

const hasAvatar = ref(false)

// Mapping agent → avatar file
const avatarMap = {
  nestor: 'nestor.png',
  tintin: 'tintin.png',
  dupont1: 'dupont1.png',
  dupont2: 'dupont2.png',
  haddock: 'haddock.png',
  rastapopoulos: 'rastapopoulos.png',
  tournesol1: 'tournesol1.png',
  tournesol2: 'tournesol1.png', // Fallback to tournesol1
  commandant: 'nestor.png' // Fallback
}

// Mapping agent → emoji (fallback)
const emojiMap = {
  nestor: '🎩',
  tintin: '🚀',
  dupont1: '🎨',
  dupont2: '🔍',
  haddock: '⚓',
  rastapopoulos: '🧔',
  tournesol1: '🧪',
  tournesol2: '🔬',
  commandant: '👨‍✈️'
}

const avatarSrc = computed(() => {
  const filename = avatarMap[props.agent] || 'nestor.png'
  return `/images/${filename}`
})

const agentEmoji = computed(() => {
  return emojiMap[props.agent] || '👤'
})

const fallbackToEmoji = () => {
  hasAvatar.value = false
}

onMounted(() => {
  // Tenter de charger l'image pour vérifier si elle existe
  const img = new Image()
  img.onload = () => {
    hasAvatar.value = true
  }
  img.onerror = () => {
    hasAvatar.value = false
  }
  img.src = avatarSrc.value
})
</script>

<style scoped>
.agent-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05));
  border: 2px solid rgba(255,255,255,0.2);
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}

.agent-avatar.small {
  width: 29px;
  height: 29px;
  border-width: 1px;
}

.agent-avatar.medium {
  width: 38px;
  height: 38px;
}

.agent-avatar.large {
  width: 58px;
  height: 58px;
  border-width: 3px;
}

.avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
}

.avatar-emoji {
  font-size: 0.8em;
  line-height: 1;
}

.agent-avatar.small .avatar-emoji {
  font-size: 12px;
}

.agent-avatar.medium .avatar-emoji {
  font-size: 16px;
}

.agent-avatar.large .avatar-emoji {
  font-size: 24px;
}

/* Style spécifique par agent */
.agent-avatar[data-agent="nestor"] {
  border-color: #9c27b0;
}

.agent-avatar[data-agent="tintin"] {
  border-color: #ff9800;
}

.agent-avatar[data-agent="dupont1"] {
  border-color: #2196f3;
}

.agent-avatar[data-agent="dupont2"] {
  border-color: #4caf50;
}

.agent-avatar[data-agent="haddock"] {
  border-color: #f44336;
}

.agent-avatar[data-agent="rastapopoulos"] {
  border-color: #9e9e9e;
}

.agent-avatar[data-agent="tournesol1"],
.agent-avatar[data-agent="tournesol2"] {
  border-color: #ffeb3b;
}
</style>