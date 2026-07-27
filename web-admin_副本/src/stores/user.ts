import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('admin_token') || '')
  const userInfo = ref<any>(JSON.parse(localStorage.getItem('admin_user') || 'null'))

  function setToken(t: string) {
    token.value = t
    localStorage.setItem('admin_token', t)
  }

  function setUserInfo(info: any) {
    userInfo.value = info
    localStorage.setItem('admin_user', JSON.stringify(info))
  }

  function logout() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
  }

  return { token, userInfo, setToken, setUserInfo, logout }
})
