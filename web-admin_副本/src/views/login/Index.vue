<template>
  <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)">
    <n-card style="width: 400px" title="管理后台登录">
      <n-form ref="formRef" :model="form" :rules="rules">
        <n-form-item path="studentId" label="工号/学号">
          <n-input v-model:value="form.studentId" placeholder="请输入工号或学号" />
        </n-form-item>
        <n-form-item path="password" label="密码">
          <n-input v-model:value="form.password" type="password" placeholder="请输入密码" @keyup.enter="handleLogin" />
        </n-form-item>
        <n-button type="primary" block :loading="loading" @click="handleLogin">登录</n-button>
      </n-form>
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { NCard, NForm, NFormItem, NInput, NButton, useMessage } from 'naive-ui'
import { useUserStore } from '../../stores/user'
import { login } from '../../api/admin'

const router = useRouter()
const message = useMessage()
const userStore = useUserStore()
const loading = ref(false)
const formRef = ref()
const form = reactive({ studentId: '', password: '' })
const rules = {
  studentId: { required: true, message: '请输入工号', trigger: 'blur' },
  password: { required: true, message: '请输入密码', trigger: 'blur' },
}

async function handleLogin() {
  await formRef.value?.validate()
  loading.value = true
  try {
    const res: any = await login(form.studentId, form.password)
    if (res.data.user.role !== 'admin') {
      message.error('该账号非管理员')
      return
    }
    userStore.setToken(res.data.token)
    userStore.setUserInfo(res.data.user)
    message.success('登录成功')
    router.push('/')
  } catch (e: any) {
    message.error(e.message || '登录失败')
  } finally {
    loading.value = false
  }
}
</script>
