import { createRouter, createWebHashHistory } from 'vue-router'
import { useUserStore } from '../stores/user'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: () => import('../views/login/Index.vue'),
    },
    {
      path: '/screen',
      name: 'Screen',
      component: () => import('../views/dashboard/Screen.vue'),
    },
    {
      path: '/',
      component: () => import('../components/Layout.vue'),
      redirect: '/dashboard',
      children: [
        { path: 'dashboard', name: 'Dashboard', component: () => import('../views/dashboard/Index.vue') },
        { path: 'schedule', name: 'Schedule', component: () => import('../views/schedule/Index.vue') },
        { path: 'announcement', name: 'Announcement', component: () => import('../views/announcement/Index.vue') },
        { path: 'semester', name: 'Semester', component: () => import('../views/semester/Index.vue') },
        { path: 'class', name: 'ClassManage', component: () => import('../views/classManage/Index.vue') },
        { path: 'product', name: 'ProductReview', component: () => import('../views/product/Index.vue') },
        { path: 'complaint', name: 'Complaint', component: () => import('../views/complaint/Index.vue') },
        { path: 'safety', name: 'Safety', component: () => import('../views/safety/Index.vue') },
      ],
    },
  ],
})

const publicPaths = ['/login', '/screen']
router.beforeEach((to, _from, next) => {
  const userStore = useUserStore()
  if (!publicPaths.includes(to.path) && !userStore.token) {
    next('/login')
  } else {
    next()
  }
})

export default router
